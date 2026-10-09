# UX refresh: trilha, sons, paleta pastel e sessão recuperada

Change OpenSpec: `openspec/changes/ux-refresh-learning-path/`.

## O que mudou

| Área | Resumo |
| --- | --- |
| Login | Biometria removida (serviço, guard, tela, strings, `local_auth`, permissões). A sessão é recuperada automaticamente: Firebase persiste o refresh token (stg/prod); em dev o `FakeAuthRemoteDataSource` grava a sessão em `SecureStorage` (`fake_session_user`) e `configureDependencies('dev')` a restaura antes do `AuthGuard`. Logout apaga a chave. |
| Rodapés | Telas com conteúdo na base (login, cadastro, perfil, editar perfil, estatísticas, home, detalhe) usam `SafeArea(top: false)`. As sessões de quiz já usavam SafeArea. |
| Trilha | Abrir um tópico (`/quiz/{topic}`) abre `TopicPathPage`: cabeçalho da unidade + nós em zigue-zague (concluído / atual com bolha "COMEÇAR" / bloqueado). Cada nó = lição de 5 questões. Progresso derivado: `floor(questões respondidas do tópico / 5)` (`TopicPathCubit`). Ao fim da lição o resumo volta para a trilha, que se atualiza. |
| Sons | `SoundService` (`shared`, `audioplayers`) com tap, acerto, erro, lição concluída, início e bloqueado + haptic. Chave "Efeitos sonoros" no Perfil (persistida). Falhas de áudio são ignoradas. |
| Paleta | Tokens pastel em `AppColors` (pêssego, creme, menta, manteiga, lilás, céu, rosa), textos escuros (`onPrimary`) sobre cores pastel, tema claro/escuro e AppBar/botões/cards/inputs arredondados. |

## Sons

Os WAVs ficam em `quiz_app/assets/sounds/` e são sintetizados por
`python3 scripts/generate_sounds.py` (sem licenças de terceiros). Para trocar um
som, substitua o arquivo mantendo o nome (`tap`, `correct`, `wrong`, `complete`,
`start`, `locked`).

## Referência de UI (Duolingo)

Rota única de nós circulares com "borda" 3D sólida, zigue-zague, cabeçalho de
unidade colorido, nó atual com bolha animada e concluídos em dourado. Fonte:
[blog do Duolingo sobre a nova home](https://blog.duolingo.com/new-duolingo-home-screen-design).

## Verificação

`dart analyze` limpo; testes de `quiz_flow` (inclui `topic_path_cubit_test.dart`),
`shared` (`sound_service_test.dart`), `quiz_module`, `question_bank`, `stats_flow`
passando. Validado no simulador iOS (iPhone 17 Pro, flavor dev) via Marionette:
login convidado → Home pastel → trilha (nó bloqueado dá snackbar) → lição de 5
questões → resumo → trilha em 1/18 com o próximo nó ativo; hot restart manteve
a sessão.

## Pendências conhecidas

- Sons não foram ouvidos em aparelho real (simulador sem verificação auditiva);
  validar volume/latência no Android.

## Atualização: resultado, aprovação por 80%, múltiplas trilhas e card que gira

| Área | Resumo |
| --- | --- |
| Tela de resultado | `LessonSummaryView`: anel de precisão animado com marca da meta (80%), título/subtítulo conforme aprovado/reprovado, pílula "Próxima lição liberada!", três métricas (XP, acertos, sequência) e lista "Para revisar" com o texto das questões erradas. Botões: **Continuar** (aprovado), **Tentar novamente** + **Voltar à trilha** (reprovado) ou **Concluir** (desafio diário/revisão). |
| Aprovação | Lição só conclui com >= 80% de acertos (`lessonPassRatio`). `LearningPathService` (quiz_module) guarda `path_completed_<tópico>` e só avança quando a lição aprovada é a atual; refazer uma lição concluída não altera a trilha. Cada lição é um bloco fixo de 5 questões (ordenadas por id), então "Tentar novamente" repete as mesmas. |
| Várias trilhas | Cada tópico é um roadmap independente com progresso próprio. A Home mostra barra e "x/y lições" em cada tópico (troféu quando terminado) e atualiza ao voltar. |
| Card que gira | Alternador "Pergunta | Explicação" acima do card, faixa fixa "Toque para ver a explicação" (pulsa) no rodapé do card, e "peek" (o card balança ao aparecer). A faixa vira "Toque para voltar à pergunta" no verso. |

Notas: o `peek` do `DsFlipCard` cede à interação do usuário (um toque durante a
dica não é mais sobrescrito); a trilha existente (derivada de questões vistas)
foi substituída pelo progresso por aprovação, então o progresso anterior não é
migrado.

## Ajustes finais

- **Streak diário (validação):** a lógica estava certa nos casos comuns (soma em
  dias seguidos, reseta ao pular, mesma data não soma), mas usava
  `completedAt - 24h` para achar "ontem". Em dias de horário de verão (23h/25h)
  isso cai no dia errado e zerava o streak indevidamente; e um relógio do
  aparelho voltando no tempo também zerava. Agora `StreakService` compara dias
  de calendário (`_calendarDaysBetween`). Cobertura: `streak_service_test.dart`
  (viradas de mês/ano, bissexto, >24h no dia seguinte, relógio voltando,
  gaps longos) e `complete_session_use_case_test.dart` (sequência real
  1→2→2→3→4 e reset após dias pulados).
  Observação: o instante é guardado sem fuso (`toIso8601String` local); se o
  usuário mudar de fuso, vale a data local atual (comportamento aceito).
- **Ícone e splash:** novos (`scripts/generate_branding.py`): nó 3D com estrela,
  ícone pêssego e splash creme (`#FFF7F0`). Regenerar nativos:
  `cd quiz_app && dart run flutter_launcher_icons && dart run flutter_native_splash:create`.
- **Sons na pergunta única** (`/question/{id}`): toque, acerto e erro.
- **"Para revisar"** no resultado mostra a contagem e esmaece a base da lista
  rolável quando há mais de uma questão.
