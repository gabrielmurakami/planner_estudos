# Planner de Provas e Estudos

App Flutter (web) para organizar as provas do semestre e o que falta estudar para cada uma. Feito como trabalho da NP2 de Desenvolvimento Mobile.

Os dados ficam no **Cloud Firestore** e são compartilhados em tempo real: o que uma pessoa do grupo cadastra aparece na hora para todas as outras.

---

## Sumário

1. [O que o app faz](#1-o-que-o-app-faz)
2. [Tecnologias](#2-tecnologias)
3. [Rodar em uma máquina nova](#3-rodar-em-uma-máquina-nova)
4. [Configurar outro projeto Firebase (opcional)](#4-configurar-outro-projeto-firebase-opcional)
5. [Comandos úteis](#5-comandos-úteis)
6. [Estrutura do projeto](#6-estrutura-do-projeto)
7. [Banco de dados](#7-banco-de-dados)
8. [Recurso adicional: BrasilAPI](#8-recurso-adicional-brasilapi)
9. [Onde está cada requisito](#9-onde-está-cada-requisito)
10. [Problemas comuns](#10-problemas-comuns)

---

## 1. O que o app faz

O app tem três telas.

### Início
- **Próxima prova:** card com imagem de capa, disciplina, tipo, data e o selo "Faltam X dias". Ao tocar no card, a agenda abre.
- **O que falta estudar:** barra de progresso por disciplina, com "X de Y tópicos" estudados (até 4 provas).
- **Próximas avaliações:** lista das provas seguintes. Ao tocar numa delas, a agenda abre já filtrada pelo tipo dessa prova (NP1, NP2 ou Exame).
- **Próximo feriado:** feriado nacional mais próximo, consultado na BrasilAPI.
- Quando não há nenhuma prova, a tela mostra os botões **Cadastrar prova** e **Adicionar 3 provas de exemplo**.
- Só aparecem provas de hoje em diante. As que já passaram continuam na agenda.

### Nova prova
- Campos **Disciplina**, **Professor(a)**, **Sala** e **Data da prova**. A data é digitada em `dd/mm/aaaa` ou escolhida no calendário.
- **Pré-visualização ao vivo:** o card se atualiza enquanto você digita.
- **Conteúdo da prova:** lista de tópicos com checkbox ("Marque o que já estudou"). Dá para adicionar e remover tópicos.
- **Tipo de avaliação:** NP1, NP2 ou Exame (grupo de Radio).
- **Aviso de feriado:** se a data cair num feriado nacional, aparece um alerta. Teste com `20/11/2026`.
- O botão **Salvar na agenda** grava a prova no Firestore e volta para a tela anterior. Quando o formulário foi aberto pela tela inicial, ela mostra a mensagem "*Disciplina* foi salva na agenda."
- O formulário já abre preenchido com um exemplo (Estatística) para agilizar a demonstração.

### Agenda
- Lista de todas as provas em tempo real, ordenadas por data.
- **Filtros:** Todas, NP1, NP2 e Exame.
- Cabeçalho com o total de avaliações e de tópicos estudados.
- Ao tocar num card, ele abre e você pode **marcar tópicos como estudados**. A mudança é gravada no Firestore e aparece para todo o grupo.
- **Excluir prova**, com confirmação.
- Etiqueta **Feriado** nas provas marcadas num feriado nacional.
- Botão **+** para cadastrar uma nova prova.

---

## 2. Tecnologias

| O quê | Versão / detalhe |
|---|---|
| Flutter | 3.35 ou mais recente (testado com 3.47) |
| Dart | 3.9 ou mais recente |
| `firebase_core` | ^4.0.0 |
| `cloud_firestore` | ^6.0.0 (banco Cloud Firestore) |
| `http` | ^1.2.0 (consumo da BrasilAPI) |
| `flutter_localizations` | datas e textos do Material em pt-BR |
| Plataforma | Web (Google Chrome ou Microsoft Edge) |

O banco é o **Cloud Firestore**, um banco NoSQL de documentos do Firebase. O app **não** usa o Realtime Database.

---

## 3. Rodar em uma máquina nova

O projeto **já está ligado ao Firebase** (projeto `tarefas-51ff3`): o arquivo `lib/firebase_options.dart` já tem as chaves. Em outra máquina **não é preciso** instalar o Firebase CLI nem rodar `flutterfire configure`. Basta ter o Flutter e um navegador.

### 3.1 Pré-requisitos

- **Flutter 3.35 ou mais recente.**
- **Google Chrome** (ou Microsoft Edge).
- **Internet**, para acessar o Firestore e a BrasilAPI.

### 3.2 Instalar o Flutter (se ainda não tiver)

Guia oficial: <https://docs.flutter.dev/get-started/install>. Escolha o sistema e depois **Web**.

<details>
<summary><b>Windows</b></summary>

1. Baixe o SDK do Flutter (arquivo `.zip`) no guia oficial.
2. Extraia em uma pasta **sem espaços nem acentos**, por exemplo `C:\src\flutter`. Não use `C:\Program Files`.
3. Adicione `C:\src\flutter\bin` à variável de ambiente **Path**: menu Iniciar → "Editar as variáveis de ambiente do sistema" → Variáveis de Ambiente → Path → Novo.
4. Feche e abra o terminal (PowerShell) de novo e rode:
   ```powershell
   flutter --version
   flutter doctor
   ```
</details>

<details>
<summary><b>macOS</b></summary>

1. Baixe o SDK do Flutter (`.zip`) no guia oficial e extraia, por exemplo, em `~/flutter`.
2. Adicione o Flutter ao PATH:
   ```bash
   echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.zshrc
   source ~/.zshrc
   ```
3. Confira:
   ```bash
   flutter --version
   flutter doctor
   ```
</details>

<details>
<summary><b>Linux</b></summary>

1. Baixe o SDK do Flutter (`.tar.xz`) no guia oficial e extraia, por exemplo, em `~/flutter`.
2. Adicione `~/flutter/bin` ao PATH no `~/.bashrc` (ou `~/.zshrc`) e abra um terminal novo.
3. Rode `flutter doctor`. Se o Chrome não for encontrado, veja a seção [Problemas comuns](#10-problemas-comuns).
</details>

No `flutter doctor`, só importam as linhas **Flutter** e **Chrome**. Avisos sobre Android Studio, Xcode ou Visual Studio podem ser ignorados, porque o app roda na web.

Se o Flutter já estiver instalado mas for anterior à 3.35, rode `flutter upgrade`.

### 3.3 Copiar o projeto

Copie a pasta `planner_estudos` inteira (pendrive, zip, Git...). As pastas `build/` e `.dart_tool/` podem ficar de fora, porque o Flutter as recria.

Confira se a pasta `web/` veio junto. Se ela estiver faltando, rode dentro da pasta do projeto:

```bash
flutter create . --platforms=web
```

Esse comando só **adiciona** o que falta. Ele não apaga nem substitui os arquivos de `lib/`.

### 3.4 Instalar as dependências e rodar

No terminal, dentro da pasta do projeto:

```bash
flutter pub get
flutter run -d chrome
```

A primeira compilação demora de 1 a 2 minutos. Depois o Chrome abre sozinho com o app.

- Sem Chrome, mas com Edge: `flutter run -d edge`.
- Para listar os navegadores que o Flutter encontrou: `flutter devices`.

Com o app rodando, use estas teclas no terminal:

| Tecla | Ação |
|---|---|
| `r` | Hot reload (aplica mudanças no código sem perder o estado) |
| `R` | Hot restart (reinicia o app) |
| `q` | Encerra o app |

### 3.5 Primeiro uso

Se a lista estiver vazia, clique em **Adicionar 3 provas de exemplo** na tela inicial ou cadastre uma pela tela **Nova prova**. A coleção precisa ter pelo menos 3 documentos reais para a apresentação.

---

## 4. Configurar outro projeto Firebase (opcional)

Só é necessário para trocar o projeto Firebase, por exemplo para usar uma conta própria em vez do `tarefas-51ff3`.

### 4.1 Criar o projeto e o banco

1. No [console do Firebase](https://console.firebase.google.com), crie um projeto. O Google Analytics pode ficar desativado.
2. No menu lateral, abra **Firestore Database**. Cuidado: **não** é "Realtime Database".
3. Clique em **Criar banco de dados**:
   - Edição: **Standard**.
   - ID do banco: deixe **`(default)`**. O app procura exatamente esse nome.
   - Local: `southamerica-east1` (São Paulo).
   - Modo inicial: tanto faz, porque as regras são trocadas no próximo passo.
4. Na aba **Regras**, cole o conteúdo do arquivo [`firestore.rules`](firestore.rules) e clique em **Publicar**.

### 4.2 Instalar as ferramentas

**Firebase CLI**

| Sistema | Comando |
|---|---|
| macOS / Linux (sem Node) | `curl -sL https://firebase.tools \| bash` |
| Qualquer sistema com Node.js | `npm install -g firebase-tools` |
| Windows sem Node | baixe o executável "standalone binary" em <https://firebase.google.com/docs/cli> |

**FlutterFire CLI**

```bash
dart pub global activate flutterfire_cli
```

Para o terminal encontrar o comando `flutterfire`, adicione a pasta de executáveis do Dart ao PATH:

- **macOS / Linux:**
  ```bash
  echo 'export PATH="$PATH:$HOME/.pub-cache/bin"' >> ~/.zshrc
  source ~/.zshrc
  ```
- **Windows:** adicione `%LOCALAPPDATA%\Pub\Cache\bin` à variável **Path** e abra um terminal novo.

### 4.3 Gerar a configuração

Na pasta do projeto:

```bash
firebase login
flutterfire configure --project=<id-do-seu-projeto>
```

Marque a plataforma **web** (e Android, se quiser). O comando substitui o `lib/firebase_options.dart` e o `firebase.json` com as chaves do novo projeto. Depois rode `flutter run -d chrome`.

---

## 5. Comandos úteis

| Comando | Para que serve |
|---|---|
| `flutter pub get` | Baixa as dependências do `pubspec.yaml` |
| `flutter run -d chrome` | Roda o app no Chrome em modo debug |
| `flutter analyze` | Procura erros e avisos no código |
| `flutter test` | Roda os testes de `test/` (funções de data) |
| `flutter build web` | Gera a versão final em `build/web/` |
| `flutter clean` | Apaga os arquivos de build. Use quando algo "travar" sem motivo e rode `flutter pub get` em seguida |

---

## 6. Estrutura do projeto

```
planner_estudos/
├── lib/
│   ├── main.dart                      # Firebase.initializeApp + MaterialApp (tema azul, pt-BR)
│   ├── firebase_options.dart          # Chaves do Firebase (gerado pelo flutterfire configure)
│   ├── models/
│   │   └── prova.dart                 # Prova, Topico e enum TipoAvaliacao (NP1/NP2/Exame)
│   ├── pages/
│   │   ├── home_page.dart             # Tela 1 — Início
│   │   ├── nova_prova_page.dart       # Tela 2 — Nova prova (formulário)
│   │   └── agenda_page.dart           # Tela 3 — Agenda em tempo real
│   ├── services/
│   │   ├── feriados_service.dart      # BrasilAPI com o pacote http (com cache por ano)
│   │   └── exemplos.dart              # 3 provas de exemplo para a demonstração
│   ├── theme/
│   │   └── cores.dart                 # Paleta: #001178 #0028B3 #1883FF #75C3FF #C5DBFF
│   ├── utils/
│   │   └── datas.dart                 # Formatação e leitura de datas (dd/mm/aaaa)
│   └── widgets/
│       └── componentes.dart           # BlocoData, Etiqueta, CartaoBranco, BarraProgresso, RotuloSecao
├── assets/images/                     # capa_estudos.png, banner_nova_prova.png, agenda_vazia.png
├── test/widget_test.dart              # Testes de lerData, diasAte e textoContagem
├── web/                               # index.html, manifest e ícones da versão web
├── firestore.rules                    # Regras do Firestore (coleção "provas")
├── firebase.json                      # Gerado pelo flutterfire configure
├── pubspec.yaml                       # Dependências e assets
└── analysis_options.yaml              # Regras do flutter_lints
```

---

## 7. Banco de dados

- **Tipo:** Cloud Firestore (NoSQL, orientado a documentos).
- **Projeto:** `tarefas-51ff3`.
- **Banco:** `(default)`, em `southamerica-east1`.
- **Coleção:** `provas`. Cada prova é um documento com ID automático.

### Documento de exemplo

```json
{
  "disciplina": "Estatística",
  "professor": "Ana",
  "sala": "Sala 12",
  "data": "Timestamp (20/11/2026 12:00)",
  "tipo": "np2",
  "topicos": [
    { "titulo": "Média, moda e mediana", "estudado": true },
    { "titulo": "Distribuição normal", "estudado": false }
  ],
  "criadoEm": "Timestamp do servidor"
}
```

| Campo | Tipo | Observação |
|---|---|---|
| `disciplina` | string | Obrigatório no formulário |
| `professor` | string | Pode ficar vazio |
| `sala` | string | Pode ficar vazio |
| `data` | timestamp | Gravado ao meio-dia, para o fuso horário não trocar o dia |
| `tipo` | string | `np1`, `np2` ou `exame` |
| `topicos` | array de mapas | `{ titulo: string, estudado: bool }` |
| `criadoEm` | timestamp | Preenchido pelo servidor (`FieldValue.serverTimestamp()`) |

### Operações usadas

| Operação | Onde |
|---|---|
| `add()` | Salvar uma prova (`nova_prova_page.dart`) e as provas de exemplo (`exemplos.dart`) |
| `orderBy('data').snapshots()` + `StreamBuilder` | Listas em tempo real (`home_page.dart`, `agenda_page.dart`) |
| `update()` | Marcar um tópico como estudado (`agenda_page.dart`) |
| `delete()` | Excluir uma prova (`agenda_page.dart`) |

### Regras de segurança

O arquivo [`firestore.rules`](firestore.rules) libera leitura e escrita na coleção `provas` para qualquer pessoa que tenha o app. Isso facilita o trabalho em grupo e a apresentação, mas **não deve ser usado em produção**: qualquer pessoa com as chaves do projeto pode ler, alterar e apagar as provas.

---

## 8. Recurso adicional: BrasilAPI

- **O que é:** consumo de uma API REST com o pacote `http`. É a mesma ideia da opção recomendada no enunciado (ViaCEP), aplicada a um dado que faz sentido num planner de provas.
- **Por que:** o app avisa quando uma prova foi marcada num feriado e mostra o próximo feriado, o que ajuda a planejar a semana de estudo.
- **Como funciona:** `GET https://brasilapi.com.br/api/feriados/v1/{ano}` devolve uma lista JSON com `date`, `name` e `type`, que é convertida em objetos `Feriado`. Cada ano é consultado uma única vez e fica em cache. Se a consulta falhar, ela é tentada de novo na próxima vez.
- **Onde aparece:**
  - Card "Próximo feriado" na tela inicial.
  - Alerta no formulário Nova prova.
  - Etiqueta "Feriado" nos cards da agenda.
- **Sem internet:** o card mostra "Não foi possível consultar agora" e o resto do app continua funcionando.
- **Fontes:** documentação da BrasilAPI (<https://brasilapi.com.br/docs>), pacote `http` no pub.dev e documentação oficial do Flutter.

---

## 9. Onde está cada requisito

Checklist para a apresentação:

| Req. | O que pede | Onde mostrar no app | Onde está no código |
|---|---|---|---|
| RF01 | Scaffold, AppBar personalizada, TextStyle | As 3 telas | `AppBar(title, centerTitle, backgroundColor)` em cada página |
| RF02 | 2+ imagens com BoxFit e ícones | Capa da próxima prova (`BoxFit.cover`), banner da Nova prova (`BoxFit.cover`), ilustração da agenda vazia (`BoxFit.contain`) | `Image.asset` em `home_page.dart`, `nova_prova_page.dart` e `agenda_page.dart` |
| RF03 | Column/Row, SingleChildScrollView, Stack + Positioned | Card da próxima prova (textos e selo "Faltam X dias" sobre a imagem) | `_CartaoProximaProva` em `home_page.dart` |
| RF04 | 3 páginas em arquivos separados, Navigator com parâmetros | Toque numa avaliação da tela inicial: a agenda abre filtrada por NP1/NP2/Exame. Ao salvar, a Nova prova devolve a disciplina para a tela inicial (SnackBar) | `AgendaPage(filtroInicial: ...)` e `Navigator.pop(context, disciplina)` |
| RF05 | StatefulWidget + setState | A pré-visualização muda enquanto você digita | `_NovaProvaPageState._aoDigitar` |
| RF06 | 3+ TextFields com label, controller e onChanged | Disciplina, Professor(a), Sala, Data e Novo tópico (5 campos) | `TextEditingController` + `.text` em `_salvar()` |
| RF07 | Checkbox e grupo de Radio com enum | Tópicos com `CheckboxListTile`; tipo com `RadioGroup<TipoAvaliacao>` | `_ListaTopicos` e `_OpcaoTipo` |
| RF08 | add(), snapshots(), StreamBuilder, indicador de carregamento | Salvar uma prova e vê-la aparecer na agenda (e no console do Firebase) | `.add(prova.toMap())`, `StreamBuilder` + `CircularProgressIndicator` |
| RF09 | Recurso adicional | Card "Próximo feriado" e aviso de feriado no formulário (teste a data 20/11/2026) | `services/feriados_service.dart` |

---

## 10. Problemas comuns

| Sintoma | Causa | Solução |
|---|---|---|
| Tela **"Falta configurar o Firebase"** | O `lib/firebase_options.dart` é o arquivo provisório | Use o arquivo do projeto ou rode `flutterfire configure` ([seção 4](#4-configurar-outro-projeto-firebase-opcional)) |
| Botão fica em **"Salvando…"** e a tela não volta; listas vazias ou carregando sem parar | O banco Firestore não foi criado (às vezes foi criado um **Realtime Database** no lugar) | Crie o **Firestore Database** com ID `(default)` ([seção 4.1](#41-criar-o-projeto-e-o-banco)) |
| Erro **`permission-denied`** ao salvar ou ler | As regras do Firestore não foram publicadas | Cole o `firestore.rules` na aba Regras do Firestore e clique em Publicar |
| **`zsh: command not found: flutterfire`** | A pasta `~/.pub-cache/bin` não está no PATH | Veja a [seção 4.2](#42-instalar-as-ferramentas) |
| `flutterfire configure` reclama do **Firebase CLI** | O comando `firebase` não está instalado | Instale o Firebase CLI ([seção 4.2](#42-instalar-as-ferramentas)) e rode `firebase login` |
| Erro com **`RadioGroup`** ao compilar | Flutter anterior à 3.35 | `flutter upgrade` |
| **`No supported devices connected`** / Chrome não aparece em `flutter devices` | O Flutter não achou o navegador | Use `flutter run -d edge` ou aponte a variável `CHROME_EXECUTABLE` para o executável do Chrome (ex.: `C:\Program Files\Google\Chrome\Application\chrome.exe`) |
| Card do feriado mostra **"Não foi possível consultar agora"** | Sem internet ou BrasilAPI fora do ar | O resto do app continua funcionando |
| Erros estranhos de build depois de copiar o projeto | Arquivos de build de outra máquina | `flutter clean` e depois `flutter pub get` |
| Aviso sobre a fonte `CupertinoIcons` no build | O app não usa esses ícones | Pode ignorar |

**Dica para o laboratório:** antes da apresentação, teste a internet da máquina (o Firestore e a BrasilAPI dependem dela) e leve um vídeo curto do app funcionando como plano B.
