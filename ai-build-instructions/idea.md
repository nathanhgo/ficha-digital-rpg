# Ideia geral

RPG o qual o projeto se destina a auxiliar: Despertar do Khaos (Pegue o contexto do projeto vendo o seguinte site: https://sites.google.com/d/12difjF-n-rs9Eu6AMAq6vevJi4OPZpia/p/18Oh9XEsS784gJj2DZ1pMsWfFsHc2srZS/edit?pli=1)

O projeto é uma ficha digital de RPG (rede social de uma mesa de RPG) que permite ao usuário criar fichas de personagens para diferentes sistemas de RPG, o sistema também deve permitir controles básicos do mestre, que possa registrar sessões, controlar iniciativas, distribuir XP e itens. O sistema deve ser mobile, feito em flutter, com processo de login simples, possivelmente usando supabase como banco de dados. O foco atual é unicamente em um sistema especifico, uma edição feita em cima de D&D (a ficha está na mesma pasta desse documento, tanto uma versão normalmente imprimida quando uma versão digital simplificada).

## Requisitos:
- O projeto deve ser feito em flutter.
- O projeto deve usar supabase como banco de dados.
- O projeto deve ter um processo de login simples.
- O projeto deve ser mobile.
- O design deve se assemelhar ao documento da Ficha do Despertar do Khaos.pdf
- O tipo de usuário "Mestre" deve ter permissão para criar, editar e deletar campanhas, sessões (com um campo para anotações gerais, hora de inicio e termino), itens (com descrição livre em texto e uma imagem opcional) e personagens. Deve poder distribuir XP, itens e dinheiro.
- O tipo de usuário "Jogador" deve ter permissão para criar, editar e deletar (com confirmação) personagens (automaticamente associado a usuário), e deve ter permissão para entrar em campanhas e sessões, registrar modificações na ficha durante as sessões (de forma simples, caso tome dano ou algo assim). Ele também deve ter um inventário, poder receber notificações (quando receber XP, ou quando uma data de sessão foi criada), a ficha dos personagens, claro, uma parte de dados pessoais (com o texto da lore, anotações gerais, documentos (que ele possa dar um "título" ao documento e subir o arquivo), etc.), ele tbm deve ter um "diário" (documento com anotações gerais q o jogador faz como se estivesse interpretando os personagens e quando ele morrer, esse documento fica público (seguindo a estrutura de documentos públicos listada a baixo)). Claro, pra isso ele precisa ter um botão de "Morrer" ou algo assim (com confirmação, para evitar perdas de personagens), ao clicar nesse botão, o personagem morre, e o diário dele se torna público, e ninguém mais consegue editar (só ler) o perfil desse personagem.
- Como seria meio complexo fechar a parte de registro e itens/personagens e tal, podemos padronizar essas coisas para terem uma imagem opcional e um campo de texto, para o usuário escrever.
- No futuro o app vai se desenvolver para algo genérico para várias mesas de RPG diferentes, mas por enquanto vamos deixar especifico para Despertar do Khaos
- Também queremos uma mecânica de documentos públicos, onde um usuário (jogador ou mestre) pode subir algo, e o mestre pode aprovar ou reprovar, caso reprove ele pode dar uma mensagem de "motivo da reprovação", mas caso aprove, seja adicionado a uma guia de "documentos públicos" do mundo do RPG, que todos os jogadores podem ver. Esses documentos devem respeitar uma categoria entre: Jornal (temos um personagem jornalista), Lore, Mapas, Pesquisas (temos pesquisas cientificas feitas pelos jogadores), Outros. Todos os documentos que passarem pela aprovação devem ter um campo de texto para o jogador poder adicionar uma versão em texto do documento ou algo assim (não impor limite de tamanho), um campo com a categoria e um campo para imagens relacionadas. Se um documento público for adicionado, os jogadores e o mestre devem receber notificação, e caso o documento seja reprovado, o jogador q fez upload do texto deve receber o motivo da reprovação (o documento só se torna público e é enviado para  s outros quando for aprovado)
- como teremos um inventário, o mestre deve poder entregar um item (como ele vai poder registrar vários itens, deve poder entregar um item já registrado ou criar um novo na hora) ár aum personagem q esteja na sessão, o player tem a opção de aceitar ou recusar (se recusar, nada acontece, mas se aceitar o item vai para o inventário dele).
- Como temos os itens, cada um deles deve ter um nome, descrição (em texto livre) e peso, e os personagens que tem inventário tem um máximo de peso
- Várias variaveis (como o peso q o personagem carrega, ou quantidade de munição, etc) dseguem algum calculo, confira as fichas para obedecer isso e sempre recalcular essas informações conforme as alterações forem feitas.
- Todas as partes da ficha devem ser preenchiveis no sistema (atributos, perícias, equipamentos, classes mágicas, história do personagem) seguindo os requisitos acima e a estrutura da ficha física/digital já feita (os documenttos PDF ao lado)

## Desafios:
- Um desafio será fazer o upload de imagens na ficha, tanto uma imagem para o personagem (Foto), como um para mapa da campanha e itens, encontre uma solução gratuita e eficiente.
- Em aspectos de programação, o sistema deve obedecer uma estrutura de TDD, criando testes antes de qualquer feature
- Em questão de segurança, crie .env e .env.example para configuração de variáveis de ambiente e siga boas práticas de segurança
- Inicie um repositório git e com gitignore, logo eu irei criar o repositório no github e fazer o primeiro commit, a partir dai, as evoluções devem ser feitas com commits curtos (que vc terá permissão para fazer), sempre fazendo teste antes de avançar


## Características gerais:
- O projeto não deve ser usado por mais de 10 pessoas (só a mesa (jogadores e mestre) da mesa mencionada)

