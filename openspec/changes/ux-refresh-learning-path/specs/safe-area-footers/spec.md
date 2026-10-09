# safe-area-footers
## ADDED Requirements
### Requirement: Rodapés respeitam a área segura
Toda tela com botões ou conteúdo ancorado na base MUST ser envolvida por SafeArea (ou aplicar `MediaQuery.padding.bottom`), de modo que nada fique sob a barra/gestos do sistema.
#### Scenario: Botão de rodapé
- **WHEN** a tela de pré-sessão/trilha, login, cadastro, perfil ou estatísticas é exibida em aparelho com barra de navegação
- **THEN** o último elemento interativo fica totalmente visível e tocável
