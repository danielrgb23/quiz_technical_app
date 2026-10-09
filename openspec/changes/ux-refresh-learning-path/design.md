# Design

## Biometria → recuperação de sessão
Firebase Auth já persiste o refresh token; `AuthRepository.isAuthenticated` considera `currentUid` ou o usuário em cache (SecureStorage). Removemos todo o fluxo de biometria. Em dev, `FakeAuthRemoteDataSource` passa a gravar o uid da sessão no `SecureStorage` (`fake_session_user`) e restaura no primeiro acesso, espelhando o comportamento real. Logout limpa a chave.

## Trilha (Duolingo)
Pesquisa: o Duolingo usa uma rota única de nós circulares com sombra "3D", em zigue-zague, cabeçalho de unidade colorido, nó atual com bolha "START" pulsando, concluídos em dourado/cor cheia e bloqueados em cinza. Adaptação:
- `TopicPathPage` substitui a `PreSessionPage` na rota `/quiz/{topic}` (deeplink preservado).
- Progresso por **aprovação**: `LearningPathService` persiste `path_completed_<tópico>`; a lição só conclui com >= 80% de acertos e só avança quando é a atual. Lição atual = próxima; demais bloqueadas. Cada lição é um bloco fixo de 5 questões (por id), repetível.
- Offset horizontal por seno (`sin(i·π/2.2)`), nós de 72px, sombra inferior sólida de 6px que some ao pressionar. Nó bloqueado dá feedback (som + snackbar).
- Lições limitadas ao total do tópico (`ceil(n/5)`); última lição com troféu.

## Sons
`SoundService` em `shared` (interface + implementação `audioplayers`, fake para testes). Assets WAV gerados por `scripts/generate_sounds.py` (tons sintetizados). Disparo na camada de página (BlocListener) para não alterar cubits/testes. Preferência "Sons" em `LocalStorage`.

## Paleta pastel
Tokens novos em `AppColors`; textos sobre cores pastel passam a usar `onPrimary` escuro (contraste). `ColorScheme.fromSeed` + overrides explícitos; `scaffoldBackgroundColor` creme.

## Riscos
- `audioplayers` em simulador: sem som se mudo; falhas de áudio são engolidas (nunca quebram o fluxo).
- Contraste: validar visualmente texto sobre pêssego.
