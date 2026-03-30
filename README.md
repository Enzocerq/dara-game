# 🎮 Projeto Dara com Sockets

## 📌 Objetivo

Este projeto tem como objetivo implementar o jogo **Dara** utilizando **Sockets** para comunicação entre jogadores, permitindo partidas em máquinas diferentes (cliente-servidor).

---

## 🧠 Sobre o Jogo

O **Dara** é um jogo de estratégia de tabuleiro de origem africana (Nigéria/Níger), jogado por duas pessoas. O objetivo principal é alinhar três peças (horizontal ou verticalmente) para capturar peças do oponente.

Apesar de lembrar o jogo da velha, o Dara possui mecânicas mais avançadas e estratégicas.

---

## 📋 Regras e Funcionamento

### 🔲 Tabuleiro

* Formado por uma grade de intersecções (geralmente **5x6**).

### 🔘 Peças

* Cada jogador inicia com **12 peças**.

### 🟡 Fase de Colocação

* Jogadores posicionam suas peças alternadamente.
* Não é permitido formar uma linha de 3 peças nesta fase.

### 🔵 Fase de Movimentação

* Após posicionar todas as peças:

  * Cada jogador move uma peça por vez.
  * Movimentos são permitidos apenas para casas adjacentes (horizontal ou vertical).

### ⚔️ Captura

* Ao alinhar **3 peças da mesma cor**, o jogador:

  * Remove uma peça do adversário do tabuleiro.

### 🏆 Condição de Vitória

* O jogo termina quando um jogador fica com apenas **2 peças**.
* Vence quem capturou mais peças.

---

## 🎥 Exemplo do Jogo

Confira um exemplo de gameplay:
👉 [Assistir no YouTube](https://www.youtube.com/watch?v=WQcX5uBTG1s&utm_source=chatgpt.com)

---

## ⚙️ Funcionalidades Implementadas

* ✅ Controle de turno (definição de quem inicia)
* 🔄 Movimentação de peças no tabuleiro
* 🏳️ Opção de desistência
* 💬 Chat em tempo real entre jogadores
* 🥇 Indicação automática do vencedor

---

## 🚀 Tecnologias Utilizadas

* Comunicação via **Sockets**
* Arquitetura cliente-servidor
