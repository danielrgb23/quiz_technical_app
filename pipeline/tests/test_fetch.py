import httpx

from pipeline.fetch import fetch_source


def make_client(handler):
    return httpx.Client(transport=httpx.MockTransport(handler))


def test_fetch_initial_download(config, source):
    def handler(request):
        return httpx.Response(200, content=b"# Questions\n")

    with make_client(handler) as client:
        result = fetch_source(source, config, client)

    assert result == {"README.md": "new"}
    target = config.raw_dir / "test_source" / "README.md"
    assert target.read_bytes() == b"# Questions\n"
    assert (config.raw_dir / "test_source" / "README.md.sha256").exists()


def test_fetch_unchanged_content(config, source):
    def handler(request):
        return httpx.Response(200, content=b"same content")

    with make_client(handler) as client:
        fetch_source(source, config, client)
        result = fetch_source(source, config, client)

    assert result == {"README.md": "unchanged"}


def test_fetch_updated_content(config, source):
    responses = [b"v1", b"v2"]

    def handler(request):
        return httpx.Response(200, content=responses.pop(0))

    with make_client(handler) as client:
        fetch_source(source, config, client)
        result = fetch_source(source, config, client)

    assert result == {"README.md": "updated"}
    target = config.raw_dir / "test_source" / "README.md"
    assert target.read_bytes() == b"v2"


def test_fetch_error_preserves_cache(config, source):
    ok = [True]

    def handler(request):
        if ok[0]:
            return httpx.Response(200, content=b"cached")
        return httpx.Response(500)

    with make_client(handler) as client:
        fetch_source(source, config, client)
        ok[0] = False
        result = fetch_source(source, config, client)

    assert result == {"README.md": "error"}
    target = config.raw_dir / "test_source" / "README.md"
    assert target.read_bytes() == b"cached"
