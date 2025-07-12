# Gerenciador de Trabalhos em Grupo

## Tutorial: Como Rodar um Aplicativo Flutter

Este tutorial guiará você pelos passos necessários para executar um aplicativo Flutter em um emulador, simulador ou dispositivo físico. Antes de começar, certifique-se de que o Flutter SDK esteja instalado e configurado corretamente em seu sistema.

1. Verificação da Instalação do Flutter
Primeiro, vamos verificar se sua instalação do Flutter está completa e se todos os requisitos estão atendidos.

 * Abra seu terminal ou prompt de comando.
 * Execute o seguinte comando:

>   flutter doctor

🔎 O comando flutter doctor analisa seu ambiente e exibe um relatório. Ele indica se há componentes faltando (como SDKs de Android ou iOS, ou IDEs) e fornece sugestões para corrigir quaisquer problemas. 

* Corrija quaisquer problemas reportados pelo flutter doctor antes de prosseguir.

2. Abrindo o Projeto Flutter

 * Navegue até o diretório raiz do seu projeto Flutter no terminal:
 * 
>   cd caminho/para/seu/projeto/flutter

 * Abra o projeto em seu editor de código preferido, como o VS Code ou Android Studio.

3. Selecionando um Dispositivo
Você pode executar seu aplicativo em um emulador Android, simulador iOS ou um dispositivo físico conectado.

3.1. Emulador Android (para Windows/Linux/macOS)

 * Certifique-se de ter o Android Studio instalado.
 * No Android Studio, vá em Tools > Device Manager (ou AVD Manager em versões mais antigas).

 * Crie um novo Virtual Device (dispositivo virtual) se ainda não tiver um.

 * Inicie o emulador a partir do Device Manager.

3.2. Simulador iOS (apenas para macOS)

 * Certifique-se de ter o Xcode instalado.
 * Abra o Xcode e vá em Xcode > Open Developer Tool

 > Simulator.

 * O simulador iOS será iniciado.

3.3. Dispositivo Físico

 * Android:

   * Habilite as Opções do Desenvolvedor em seu dispositivo Android (geralmente tocando várias vezes no "Número da Compilação" nas informações do telefone).

   * Habilite a Depuração USB nas Opções do Desenvolvedor.

   * Conecte seu dispositivo Android ao computador via cabo USB.

   * Aceite a solicitação de depuração USB no seu dispositivo.
 * iOS (apenas macOS):

   * Conecte seu iPhone/iPad ao Mac via cabo USB.

   * Confie no computador se for solicitado no dispositivo.

   * Pode ser necessário abrir o Xcode e permitir que ele processe o dispositivo pela primeira vez.

4. Listando Dispositivos Disponíveis
No terminal, execute o seguinte comando para ver os dispositivos conectados e emuladores/simuladores disponíveis:
flutter devices

✨ Você verá uma lista de dispositivos, como emuladores Android, simuladores iOS ou dispositivos físicos, com seus respectivos IDs.

5. Rodando o Aplicativo
Com um dispositivo selecionado e iniciado (ou conectado), você pode rodar seu aplicativo.

5.1. Rodar no Dispositivo Padrão
Se houver apenas um dispositivo disponível ou se você quiser que o Flutter escolha o melhor, execute:
flutter run

5.2. Rodar em um Dispositivo Específico
Se você tem vários dispositivos e quer especificar qual usar, use a flag -d seguida pelo ID do dispositivo (obtido via flutter devices):
flutter run -d <device_id>

Por exemplo:
 * Emulador Android: flutter run -d emulator-5554
 * Simulador iOS: flutter run -d A906E881-A61F-43B0-8CAE-226B22329A3F (o ID será diferente para você)
 * Dispositivo Android Físico: flutter run -d SM-G973F (substitua pelo ID do seu dispositivo)

6. Depuração e Hot Reload/Restart
Enquanto o aplicativo estiver rodando, você pode usar os seguintes comandos no terminal:

 * r: Hot Reload ⚡️ - Recarrega rapidamente o código modificado na tela sem perder o estado atual do aplicativo. Perfeito para pequenos ajustes na UI.
 * R: Hot Restart 🔄 - Recarrega completamente o aplicativo, perdendo o estado, mas recarregando todo o código. Bom para mudanças maiores que afetam o estado.
 * q: Sair do processo de execução.

Parabéns! 🎉

Você agora sabe como rodar seu aplicativo Flutter em diferentes ambientes. Continue explorando e desenvolvendo seus projetos!

## 📋 User Stories Implementadas

**Módulo de Grupos: 4/4 user stories principais implementadas** 
**Módulo de Tarefas: 7/7 user stories implementadas**
**Módulo de Comentários: 3/3 user stories implementadas (US019-US021)**
**Módulo de Rótulos: 3/3 user stories implementadas (US016-US018)**
**Módulo de Anexos: 3/3 user stories implementadas (US022-US024)**
**Total: 20 user stories concluídas**

### ✅ US005 - Criar Grupo
**Como** usuário logado  
**Eu quero** criar um novo grupo de trabalho  
**Para que** eu possa organizar tarefas por projeto/equipe  

**Critérios de Aceitação Implementados:**
- ✅ **Nome e descrição obrigatórios** - Validação de formulário implementada
- ✅ **Criador automaticamente vira administrador** - Primeiro usuário é definido como 'admin'
- ✅ **Validação de nome único por usuário** - Método `hasGroupWithSameName()` implementado
- ✅ **Log da criação do grupo** - Sistema de auditoria com `AtividadeRepository`

**Funcionalidades Implementadas:**
- Criação de grupos com validação completa
- Seleção de cor personalizada para o grupo
- Configuração de visibilidade (público/privado)
- Definição de número máximo de membros
- Busca e adição de membros por nome/email
- Sistema de papéis (admin/membro)
- Auditoria completa das ações

**Correções Técnicas:**
- Corrigido SQL injection em `UsuarioGrupoRepository`
- Implementado `Sql.named()` em todos os repositórios
- Adicionado sistema de log de atividades
- Validação de nomes únicos por usuário

---

### ✅ US006 - Visualizar Grupos
**Como** usuário logado  
**Eu quero** visualizar todos os grupos que participo  
**Para que** eu possa navegar entre diferentes projetos  

**Critérios de Aceitação Implementados:**
- ✅ **Lista de grupos do usuário** - Método `getGruposDoUsuario()` implementado
- ✅ **Informações básicas dos grupos** - Cards com nome, descrição, membros e papel
- ✅ **Filtro por papel** - Filtrar por admin/moderador/membro
- ✅ **Busca por nome** - Busca em tempo real por nome ou descrição
- ✅ **Ordenação flexível** - Por data de entrada, nome ou número de membros
- ✅ **Estatísticas visuais** - Contadores por papel do usuário

**Funcionalidades Implementadas:**
- Página dedicada de listagem de grupos (`GroupListPage`)
- Cards visuais com informações detalhadas
- Sistema de filtros e busca avançada
- Estatísticas dos grupos por papel
- Navegação integrada desde a home page
- Indicadores visuais de papel (admin/moderador/membro)
- Refresh pull-to-refresh
- Estados vazios informativos

**Modelo de Dados:**
- `GrupoComInfo` - Modelo composto com grupo + informações do usuário
- Queries otimizadas com JOIN para performance
- Contagem de membros em tempo real

---

### ✅ US007 - Gerenciar Membros do Grupo
**Como** administrador ou moderador de um grupo  
**Eu quero** gerenciar os membros do grupo  
**Para que** eu possa controlar quem participa e seus papéis  

**Critérios de Aceitação Implementados:**
- ✅ **Lista de membros com detalhes** - Página dedicada com informações completas
- ✅ **Adicionar novos membros** - Busca e adição com seleção de papel
- ✅ **Remover membros existentes** - Remoção com confirmação e validações
- ✅ **Alterar papéis dos membros** - Mudança de papel admin/moderador/membro
- ✅ **Validação de permissões** - Controle baseado no papel do usuário
- ✅ **Proteções de segurança** - Não remover único admin, não auto-rebaixar
- ✅ **Auditoria completa** - Log de todas as ações de gerenciamento

**Funcionalidades Implementadas:**
- Página dedicada de gerenciamento de membros (`GroupMembersPage`)
- Sistema de busca de usuários não-membros
- Diálogos interativos para adicionar e alterar papéis
- Estatísticas visuais de membros por papel
- Validações de negócio para proteção do grupo
- Sistema de permissões baseado em papéis
- Logs detalhados de todas as ações administrativas
- Interface responsiva com feedback visual

**Modelo de Dados:**
- `MembroGrupo` - Modelo composto com usuário + informações do grupo
- Métodos de gerenciamento no `UsuarioGrupoRepository`
- Queries otimizadas para busca e listagem
- Sistema de auditoria integrado

**Proteções de Segurança:**
- Usuário não pode remover a si mesmo
- Não é possível remover o único administrador
- Usuário não pode rebaixar seu próprio papel
- Validação de permissões em todas as operações

---

### ✅ US008 - Sair do Grupo / Configurações do Grupo
**Como** membro de um grupo  
**Eu quero** sair de um grupo e editar suas configurações  
**Para que** eu possa gerenciar minha participação e configurar o grupo adequadamente  

**Critérios de Aceitação Implementados:**
- ✅ **Confirmação antes de sair** - Dialog de confirmação com aviso sobre remoção de tarefas
- ✅ **Remoção de atribuições de tarefas** - Usuário é removido de todas as tarefas do grupo automaticamente
- ✅ **Proteção do único admin** - Único administrador não pode sair do grupo
- ✅ **Editar informações básicas** - Nome e descrição do grupo com validação de nomes únicos
- ✅ **Configurações avançadas** - Cor do tema, visibilidade (público/privado), máximo de membros
- ✅ **Validação de permissões** - Apenas admin/moderador pode editar configurações
- ✅ **Auditoria completa** - Log de todas as ações de configuração e saída

**Funcionalidades Implementadas:**
- Página dedicada de configurações (`GroupSettingsPage`)
- Interface dividida em seções organizadas (Informações, Configurações, Ações)
- Editor de informações básicas com validação
- Seletor de cores para tema do grupo
- Configuração de visibilidade (público/privado)
- Slider para definir máximo de membros (5-200)
- Funcionalidade de sair do grupo com validações
- Sistema de permissões baseado em papéis
- Logs detalhados de todas as ações
- Navegação integrada via menu popup

**Modelo de Dados e Métodos:**
- `podeUsuarioSairDoGrupo()` - Valida se usuário pode sair (não é único admin)
- `sairDoGrupo()` - Remove atribuições de tarefas e desativa membro
- `temPermissaoEditarGrupo()` - Verifica permissões para editar
- `atualizarInformacoesBasicas()` - Atualiza nome e descrição
- `atualizarConfiguracoes()` - Atualiza configurações específicas
- `hasGroupWithSameNameForEdit()` - Validação de nome único para edição

**Proteções e Validações:**
- Único administrador não pode sair do grupo
- Validação de nomes únicos por usuário ao editar
- Verificação de permissões para editar configurações
- Remoção automática de atribuições de tarefas ao sair
- Interface adaptativa baseada em permissões do usuário
- Confirmação obrigatória para ações destrutivas

**Integração com Sistema:**
- Acessível via menu popup na página do grupo
- Navegação inteligente (volta para home se usuário sair do grupo)
- Integrado com sistema de logs de atividades
- Atualizações em tempo real na interface

---

## 🔧 Funcionalidades Anteriores

### ✅ Módulo de Grupos Completo
- **US005**: Criar Grupo (com validações e auditoria)
- **US006**: Visualizar Grupos (com filtros e estatísticas)
- **US007**: Gerenciar Membros do Grupo (adicionar, remover, alterar papéis)
- **US008**: Sair do Grupo / Configurações do Grupo (editar informações e configurações)

### ✅ Módulo de Tarefas Completo
- **US009**: Criar Tarefa
- **US010**: Visualizar Lista de Tarefas  
- **US011**: Visualizar Detalhes da Tarefa
- **US012**: Editar Tarefa
- **US013**: Excluir Tarefa
- **US014**: Atribuir Responsáveis
- **US015**: Comentários em Tarefas (incluindo respostas)

---

### ✅ US016-US018 - Sistema de Rótulos
**Como** usuário de um grupo  
**Eu quero** criar e aplicar rótulos às tarefas  
**Para que** eu possa categorizar e filtrar tarefas de forma organizada  

**Critérios de Aceitação Implementados:**
- ✅ **US016 - Criar e Gerenciar Rótulos**
  - ✅ Administradores e moderadores podem criar rótulos personalizados por grupo
  - ✅ Configuração de nome, descrição e cor para cada rótulo
  - ✅ Validação de nomes únicos por grupo
  - ✅ Interface intuitiva com seletor de cores predefinidas
  - ✅ Estatísticas de uso dos rótulos

- ✅ **US017 - Aplicar Rótulos às Tarefas**
  - ✅ Aplicação de múltiplos rótulos por tarefa
  - ✅ Interface de gerenciamento com seleção múltipla
  - ✅ Visualização dos rótulos nas listas de tarefas
  - ✅ Remoção e edição de rótulos aplicados
  - ✅ Log de atividades para alterações

- ✅ **US018 - Filtrar Tarefas por Rótulos**
  - ✅ Filtro por múltiplos rótulos simultaneamente
  - ✅ Integração com filtros existentes (status, prioridade)
  - ✅ Interface de seleção com visualização das cores
  - ✅ Contador de tarefas filtradas

---

### ✅ US022-US024 - Sistema de Anexos
**Como** membro de grupo  
**Eu quero** anexar, baixar e gerenciar arquivos nas tarefas  
**Para que** eu possa compartilhar documentos relevantes ao trabalho  

**Critérios de Aceitação Implementados:**
- ✅ **US022 - Anexar Arquivo à Tarefa**
  - ✅ Upload de múltiplos arquivos simultaneamente
  - ✅ Validação de tipo e tamanho (máx. 50MB)
  - ✅ Suporte a 25+ tipos de arquivo (documentos, imagens, vídeos, áudio, compactados)
  - ✅ Armazenamento seguro com nomes únicos
  - ✅ Detecção automática de tipo MIME
  - ✅ Interface intuitiva com feedback de progresso

- ✅ **US023 - Download de Anexo**
  - ✅ Download direto e seguro para pasta de downloads
  - ✅ Preservação do nome original do arquivo
  - ✅ Verificação de integridade do arquivo
  - ✅ Botão para abrir pasta de destino
  - ✅ Feedback visual durante download

- ✅ **US024 - Remover Anexo**
  - ✅ Remoção apenas pelo autor do anexo
  - ✅ Confirmação obrigatória antes da remoção
  - ✅ Limpeza do arquivo físico do sistema
  - ✅ Log da ação de remoção
  - ✅ Interface com permissões baseadas no usuário

**Funcionalidades Técnicas:**
- Widget reutilizável `FileAttachmentWidget`
- Ícones específicos por tipo de arquivo
- Formatação automática de tamanhos de arquivo
- Integração com `file_picker`, `path_provider` e `mime`
- Sistema de permissões robusto
- Tratamento de erros completo
- Interface responsiva e acessível

**Funcionalidades Implementadas:**
- Página dedicada de gerenciamento de rótulos (`LabelManagementPage`)
- Dialog para aplicação de rótulos às tarefas (`TaskLabelsDialog`)
- Widget de visualização de rótulos inline (`TaskLabelsWidget`)
- Sistema de filtros integrado na página de grupos
- Paleta de 19 cores predefinidas com preview em tempo real
- Estatísticas de uso e contadores por rótulo
- Validações de segurança e permissões
- Auditoria completa das ações

**Modelo de Dados:**
- `Rotulo` - Modelo básico com nome, descrição, cor e grupo
- `TarefaRotulo` - Relacionamento many-to-many tarefa-rótulo
- `RotuloRepository` - CRUD completo com validações e estatísticas
- `TarefaRotuloRepository` - Gerenciamento de associações e filtros

**Características Visuais:**
- Chips coloridos com bordas temáticas
- Seletor de cores interativo
- Preview em tempo real
- Indicadores de estado e contadores
- Interface responsiva e intuitiva

**Segurança e Validações:**
- Todas as queries SQL parametrizadas com `Sql.named()`
- Validação de permissões baseada em papéis
- Nomes únicos por grupo
- Cascading deletes para associações
- Auditoria integrada

## 🚀 Próximas Implementações

### 🔄 **Próximas Recomendações:**

#### **1. US001-US004 - Sistema de Autenticação** 🔐
- **US001**: Cadastro de usuários com validação
- **US002**: Login com validação de credenciais
- **US003**: Logout seguro
- **US004**: Perfil do usuário editável
- Substituir sistema mock atual por autenticação real

#### **2. US025-US026 - Sistema de Notificações** 🔔
- **US025**: Receber notificações de atividades relevantes
- **US026**: Configurar preferências de notificação
- Sistema em tempo real para engajamento

#### **3. US027-US028 - Dashboard e Relatórios** 📊
- **US027**: Dashboard principal com resumo das atividades
- **US028**: Relatórios de produtividade da equipe
- Analytics e métricas para gestão

---

## 🏗️ Arquitetura Técnica

### Banco de Dados
- **PostgreSQL** com conexão direta
- **Validação de SQL** com `Sql.named()` para segurança
- **Sistema de Auditoria** com tabela `atividades`

### Modelos Implementados
- `Grupo` - Informações básicas do grupo
- `UsuarioGrupo` - Relacionamento usuário-grupo com papéis
- `Atividade` - Log de ações para auditoria

### Validações
- Nome único por usuário
- Validação de formulários
- Controle de permissões por papel
- Logs automáticos de criação
