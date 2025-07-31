*&---------------------------------------------------------------------*
*& Report ZP_AISDKDEMO_CHTCMPL_SMPL_OAI
*&---------------------------------------------------------------------*
*& PROPÓSITO: Demonstração de como integrar SAP ABAP com Inteligência
*&            Artificial usando OpenAI/Azure OpenAI
*& 
*& FUNCIONALIDADE: Este programa mostra como enviar prompts para modelos
*&                 de IA e receber respostas inteligentes diretamente
*&                 no ambiente SAP
*&---------------------------------------------------------------------*
REPORT zp_aisdkdemo_chtcmpl_smpl_oai.

" Inclusão de parâmetros comuns da IA (URL do endpoint, versão da API, chave de acesso)
INCLUDE zp_msaisdkdemo_params_top_oai.  

" Inclusão de declarações de dados comuns (instância do SDK, códigos de status, JSON de retorno, erros)
INCLUDE zp_msaisdkdemo_common.      

" PARÂMETROS DE ENTRADA ESPECÍFICOS DESTE PROGRAMA
PARAMETERS:
    " ID do modelo de IA que será usado (ex: 'gpt-4', 'gpt-35-turbo')
    " No Azure OpenAI, cada modelo tem um nome de deployment único
    p_depid  TYPE string OBLIGATORY LOWER CASE.

" ESTRUTURAS DE DADOS PARA COMUNICAÇÃO COM A IA
DATA:
  " Estrutura que contém a pergunta/prompt que será enviado para a IA
  " Inclui as mensagens de sistema (configuração) e usuário (pergunta real)
  chatcompl_input  TYPE zif_peng_azoai_sdk_types=>ty_chatcompletion_input,
  
  " Estrutura que receberá a resposta da IA
  " Contém as escolhas de resposta geradas pelo modelo de linguagem
  chatcompl_output TYPE zif_peng_azoai_sdk_types=>ty_chatcompletion_output.


START-OF-SELECTION.

  " BLOCO DE TRATAMENTO DE ERROS - Protege contra falhas na comunicação com IA
  TRY.
      " ====================================================================
      " PASSO 1: INICIALIZAÇÃO DO SDK DE IA
      " ====================================================================
      " Cria uma instância do SDK (Software Development Kit) para comunicação
      " com os serviços de IA da Microsoft Azure OpenAI ou OpenAI
      " 
      " Parâmetros necessários:
      " - api_version: Versão da API (ex: 'v1')
      " - api_base: URL base do serviço (ex: 'https://api.openai.com')
      " - api_type: Tipo de API (OpenAI neste caso)
      " - api_key: Chave de autenticação para acessar o serviço
      sdk_instance = zcl_peng_azoai_sdk_factory=>get_instance( )->get_sdk(
                                                            api_version = p_ver
                                                            api_base    = p_url
                                                            api_type    = zif_peng_azoai_sdk_constants=>c_apitype-openai
                                                            api_key     = p_key
                                                          ).

      " ====================================================================
      " PASSO 2: CONSTRUÇÃO DA CONVERSA COM A IA
      " ====================================================================
      " A IA funciona como uma conversa entre diferentes "papéis":
      " - SYSTEM: Define o comportamento e especialidade da IA
      " - USER: A pergunta ou solicitação do usuário
      " - ASSISTANT: A resposta da IA (será preenchida automaticamente)
      
      " PRIMEIRA MENSAGEM: Definindo o papel da IA como especialista em ABAP
      " Isso instrui a IA sobre como ela deve se comportar e responder
      APPEND INITIAL LINE TO chatcompl_input-messages ASSIGNING FIELD-SYMBOL(<fs_message>).
      <fs_message>-role = zif_peng_azoai_sdk_constants=>c_chatcompletion_role-system.
      <fs_message>-content = |You are an expert ABAP Developer|.

      " SEGUNDA MENSAGEM: A pergunta/solicitação real do usuário
      " Neste exemplo, pedimos para a IA escrever um programa ABAP específico
      APPEND INITIAL LINE TO chatcompl_input-messages ASSIGNING <fs_message>.
      <fs_message>-role = zif_peng_azoai_sdk_constants=>c_chatcompletion_role-user.
      <fs_message>-content = |Write an ABAP program which gets contents from www.microsoft.com website. Include comments in the code so that anyone can understand the code.|.

      " ====================================================================
      " PASSO 3: ENVIO DA CONVERSA PARA A IA E RECEBIMENTO DA RESPOSTA
      " ====================================================================
      " Esta é a chamada principal que:
      " 1. Envia nossa conversa (prompt) para o modelo de IA especificado
      " 2. Aguarda a IA processar e gerar uma resposta
      " 3. Recebe de volta a resposta junto com informações de status
      " 
      " PARÂMETROS DE ENTRADA (EXPORTING):
      " - deploymentid: Nome do modelo específico de IA a ser usado
      " - prompts: Nossa conversa formatada (system + user messages)
      " 
      " PARÂMETROS DE SAÍDA (IMPORTING):
      " - statuscode: Código HTTP da operação (200 = sucesso, 400+ = erro)
      " - statusreason: Descrição textual do status
      " - json: Resposta completa em formato JSON (dados brutos)
      " - response: Resposta estruturada em tipos ABAP (dados processados)
      " - error: Detalhes de erro caso algo dê errado
      sdk_instance->chat_completions( )->create(
        EXPORTING
          deploymentid = p_depid
          prompts      = chatcompl_input
        IMPORTING
          statuscode   = status_code                  " Status Code
          statusreason = status_reason                " HTTP status description
          json         = returnjson                   " JSON String returned from AI Resource
          response     = chatcompl_output
          error        = error                        " ABAP Ready error details
      ).

      " ====================================================================
      " PASSO 4: EXIBIÇÃO DO RESULTADO GERADO PELA IA
      " ====================================================================
      " A IA pode gerar múltiplas opções de resposta (choices), mas normalmente
      " usamos apenas a primeira [1]. A resposta está em:
      " chatcompl_output-choices[1]-message-content
      " 
      " cl_demo_output é uma classe SAP padrão para exibir texto em tela
      cl_demo_output=>display_text( text = chatcompl_output-choices[ 1 ]-message-content ).

    " ====================================================================
    " TRATAMENTO DE ERROS ESPECÍFICOS E GERAIS
    " ====================================================================
    " ERRO 1: Exceções específicas do SDK de IA
    " Captura erros relacionados à comunicação com a IA, problemas de autenticação,
    " modelos não encontrados, limites de uso excedidos, etc.
    CATCH zcx_peng_azoai_sdk_exception INTO DATA(ex). " MSPENG:Azure Open AI ABAP SDK Exception
      " Exibe a mensagem de erro específica do SDK
      MESSAGE ex TYPE 'I'.

    " ERRO 2: Qualquer outro tipo de erro não previsto
    " Captura problemas gerais como falhas de rede, timeouts, etc.
    CATCH cx_root.
      " Mensagem genérica com sugestões de possíveis causas
      MESSAGE |Ocorreu um erro - talvez o nome do modelo esteja incorreto? Ou a chave de acesso está inválida?| TYPE 'I'.

  ENDTRY.
