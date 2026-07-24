"""CLI do pipeline: python -m pipeline {fetch,parse,generate,validate,export,run}."""

from __future__ import annotations

import argparse
import logging
import sys
from pathlib import Path

from . import config as config_mod
from .export import run_export
from .fetch import run_fetch
from .generate import run_generate
from .parse import run_parse
from .validate import run_validate


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="pipeline")
    parser.add_argument("--sources", type=Path, default=Path("sources.yaml"))
    parser.add_argument("--data-dir", type=Path, default=Path("data"))
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("fetch", help="baixa/atualiza fontes")
    sub.add_parser("parse", help="markdown -> pares Q/A")

    gen = sub.add_parser("generate", help="Q/A -> MCQ (usa LLM)")
    gen.add_argument("--dry-run", action="store_true")
    gen.add_argument("--limit", type=int, default=None)

    sub.add_parser("validate", help="valida e deduplica")

    exp = sub.add_parser("export", help="gera JSON versionado")
    exp.add_argument("--bump", action="store_true")

    run = sub.add_parser("run", help="tudo em sequência")
    run.add_argument("--dry-run", action="store_true")
    run.add_argument("--limit", type=int, default=None)
    run.add_argument("--bump", action="store_true")
    return parser


def make_llm_client() -> "object":
    from .llm import AnthropicClient

    return AnthropicClient(model=config_mod.get_model())


def main(argv: list[str] | None = None) -> int:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s: %(message)s")
    args = build_parser().parse_args(argv)
    config_mod.load_env()
    config = config_mod.load_config(args.sources, args.data_dir)

    if args.command == "fetch":
        run_fetch(config)
    elif args.command == "parse":
        run_parse(config)
    elif args.command == "generate":
        client = None if args.dry_run else make_llm_client()
        run_generate(config, client, dry_run=args.dry_run, limit=args.limit)
    elif args.command == "validate":
        run_validate(config)
    elif args.command == "export":
        run_export(config, bump=args.bump)
    elif args.command == "run":
        run_fetch(config)
        run_parse(config)
        client = None if args.dry_run else make_llm_client()
        stats = run_generate(config, client, dry_run=args.dry_run, limit=args.limit)
        if args.dry_run:
            print(f"dry-run: {stats['planned']} chamadas ao LLM seriam feitas")
            return 0
        run_validate(config)
        run_export(config, bump=args.bump)
    return 0


if __name__ == "__main__":
    sys.exit(main())
