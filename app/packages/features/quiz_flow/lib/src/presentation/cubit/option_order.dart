/// Gera uma nova ordem de exibição para as alternativas: embaralha os
/// índices originais para que o usuário não decore a posição da resposta
/// certa entre uma sessão e outra.
List<int> shuffledOptionOrder(int length) =>
    List.generate(length, (i) => i)..shuffle();
