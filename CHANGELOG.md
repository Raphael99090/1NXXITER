# Changelog

Todas as mudanças notáveis do 1NXITER HUB são documentadas aqui.

## [Não lançado]

### Adicionado
- Sistema de key fixa (`main.lua`) antes de carregar qualquer módulo — tela de input com validação e mensagem de erro. **Apenas para teste**: a key fica em texto puro no código, sem segurança real ainda.
- Ícone customizado na bolinha flutuante, baixado do repositório (`Assets/1784776415112.png`) via `writefile`/`getcustomasset`, com fallback pro texto "1NX" caso o executor não suporte.
- `UIAspectRatioConstraint` na bolinha flutuante, pra ela nunca esticar/virar elipse em resoluções diferentes.
- Sombra suave (drop-shadow) atrás da bolinha flutuante.
- Efeito de glow pulsante no contorno da bolinha enquanto o hub está minimizado.
- Snap automático pra borda esquerda/direita da tela ao soltar o drag da bolinha, com clamp vertical pra nunca sair da viewport.
- Fade-in suave do ícone customizado quando termina de carregar, e fade-out do texto de fallback.

### Corrigido
- Bolinha flutuante não aparecia ao minimizar o hub — a detecção antiga tentava adivinhar qual `Frame` da Fluent era o principal e escutar `.Visible`, o que é frágil na v3 da Fluent (que anima minimize/restore sem necessariamente tocar em `.Visible`). Trocado por um hook direto em `Window:Minimize`, que cobre tanto o clique na bolinha quanto o `MinimizeKey` (LeftControl).
- Clique na bolinha não restaurava a janela — a chamada `Window:Minimize(false)` estava tratando o parâmetro como "estado desejado", mas ele provavelmente é uma flag de animação/instant, não o estado alvo. Trocado por `Window:Minimize()` como toggle puro, igual o keybind interno já fazia.

### Alterado
- Paleta de cores da bolinha flutuante trocada de vermelho genérico pra roxo/dourado, combinando com a logo do hub.

### Removido
- Badge de atividade (pontinho verde indicando feature ativa em segundo plano) — implementado e depois removido a pedido, por não ser necessário no momento.
