# Refresh de UX: trilha estilo Duolingo, sons, paleta pastel e login simplificado

## Why

O app precisa ficar mais lúdico e menos atritoso: o desbloqueio por biometria adiciona um passo de login sem ganho real (a sessão já é persistida), os rodapés ficam sob os botões de navegação do sistema, a escolha de tópico cai num formulário seco e a identidade visual (roxo/ciano saturados) não combina com a proposta leve de estudo.

## What Changes

- **Remover o login por biometria** (serviço, preferências, guard, tela de bloqueio, diálogo pós-login, `local_auth`, strings, permissão iOS). **BREAKING** para quem tinha biometria ativada: a flag fica órfã e é ignorada.
- **Recuperação de sessão**: após o primeiro login a sessão é restaurada automaticamente nas próximas aberturas (token de refresh do Firebase em stg/prod; em dev o fake persiste a sessão em SecureStorage para o fluxo ser testável).
- **Rodapés com SafeArea** em todas as telas com ações/botões na base.
- **Trilha de aprendizado** (inspirada no Duolingo) ao abrir um tópico: cabeçalho da unidade, nós circulares em zigue-zague, estados concluído / atual / bloqueado, bolha "COMEÇAR" no nó atual; cada nó é uma lição de 5 questões.
- **Efeitos sonoros** (acerto, erro, toque, lição concluída) + haptics, com chave "Sons" no perfil.
- **Paleta pastel** (laranja-pêssego, creme, menta, manteiga) em tokens, tema claro/escuro e telas que usavam cores fixas.

## Capabilities

### New Capabilities
- `session-recovery`, `safe-area-footers`, `learning-path`, `sound-effects`, `pastel-theme`

### Modified Capabilities
- `app-identity`/auth: biometria removida (ver design).

## Impact

- `auth_module`, `auth_flow`, `profile_flow`, `quiz_flow`, `home_flow`, `design_system`, `shared`, `quiz_app` (rotas, DI, assets, pubspec, Info.plist).
- Novos assets `quiz_app/assets/sounds/*.wav` (gerados por script, sem licenças de terceiros).
