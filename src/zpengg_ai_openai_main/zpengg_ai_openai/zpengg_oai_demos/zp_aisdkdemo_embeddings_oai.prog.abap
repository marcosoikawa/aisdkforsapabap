*&---------------------------------------------------------------------*
*& Report ZP_AISDKDEMO_EMBEDDINGS_OAI
*&---------------------------------------------------------------------*
*& 
*& DESCRIÇÃO: Este programa demonstra como gerar embeddings de texto utilizando
*& o SDK da Microsoft para integração do SAP com serviços de IA do OpenAI.
*& 
*& PROPÓSITO:
*& Embeddings são representações vetoriais de texto em formato numérico que 
*& capturam o significado semântico do conteúdo. São úteis para:
*&   - Buscas semânticas em documentos
*&   - Análises de similaridade entre textos
*&   - Base para sistemas de recomendação
*&   - Classificação de documentos
*& 
*& REQUISITOS:
*&   - Acesso configurado ao serviço OpenAI
*&   - Deployment de modelo de embeddings ativo
*&---------------------------------------------------------------------*
REPORT zp_aisdkdemo_embeddings_oai.

*----------------------------------------------------------------------*
* INCLUDES: Importação de componentes comuns para todos os programas 
* de demonstração do SDK
*----------------------------------------------------------------------*
INCLUDE zp_msaisdkdemo_params_top_oai.  "Parâmetros de entrada comuns (URL, versão da API, chave)
INCLUDE zp_msaisdkdemo_common.          "Declarações de dados comuns (Objeto SDK, códigos de status, etc)

*----------------------------------------------------------------------*
* DECLARAÇÃO DA INSTÂNCIA SDK: Objeto principal para interagir com a API
*----------------------------------------------------------------------*
DATA sdk_instance TYPE REF TO zif_peng_azoai_sdk.
* PARÂMETROS DE ENTRADA: Coletados na tela de seleção
*----------------------------------------------------------------------*
PARAMETERS:
    p_depid  TYPE string OBLIGATORY LOWER CASE.  "ID do deployment do modelo de embeddings no OpenAI
                                                 "Exemplo: text-embedding-ada-002

*----------------------------------------------------------------------*
* ESTRUTURAS DE DADOS: Definição das variáveis para entrada e saída
*----------------------------------------------------------------------*
DATA:
  embeddings_input  TYPE zif_peng_azoai_sdk_types=>ty_embeddings_input,   "Estrutura para armazenar textos de entrada
  embeddings_output TYPE zif_peng_azoai_sdk_types=>ty_embeddings_output.  "Estrutura para receber vetores de embeddings


START-OF-SELECTION.

  TRY.
*----------------------------------------------------------------------*
* PASSO 1: Inicialização do SDK da Microsoft para IA no SAP
* - Cria uma instância do SDK para comunicação com o serviço OpenAI
* - Configura os parâmetros de conexão fornecidos pelo usuário
*----------------------------------------------------------------------*
      sdk_instance = zcl_peng_azoai_sdk_factory=>get_instance( )->get_sdk(
                                                            api_version = p_ver    "Versão da API (ex: v1)
                                                            api_base    = p_url    "URL base do serviço OpenAI
                                                            api_type    = zif_peng_azoai_sdk_constants=>c_apitype-openai  "Tipo de API (OpenAI)
                                                            api_key     = p_key    "Chave de autenticação da API
                                                          ).

*----------------------------------------------------------------------*
* PASSO 2: Preparação dos textos para geração de embeddings
* - Adiciona os textos de entrada para os quais desejamos gerar vetores
* - Neste exemplo, usamos um texto simples "Hello world!"
* - Na prática, podem ser descrições de produtos, documentos, etc.
*----------------------------------------------------------------------*
      APPEND INITIAL LINE TO embeddings_input-input ASSIGNING FIELD-SYMBOL(<fs_embedinput>).
      <fs_embedinput> = 'Hello world!'.  "Texto de exemplo para geração de embedding

*----------------------------------------------------------------------*
* PASSO 3: Chamada à API de Embeddings do OpenAI
* - Envia os textos para processamento
* - Solicita a geração dos vetores de embeddings
* - Armazena os resultados (vetores) retornados pela API
*----------------------------------------------------------------------*
      sdk_instance->embeddings( )->create(
        EXPORTING
          deploymentid = p_depid            "ID do modelo de embeddings no Azure OpenAI
          inputs       = embeddings_input   "Textos de entrada para processamento
        IMPORTING
          statuscode   = status_code        "Código HTTP de status da chamada
          statusreason = status_reason      "Descrição do status HTTP
          json         = returnjson         "JSON original retornado pela API
          response     = embeddings_output  "Resposta convertida para estrutura ABAP
          error        = error              "Detalhes de erro, se houver
      ).

*----------------------------------------------------------------------*
* PASSO 4: Análise dos resultados
* - Neste ponto os vetores de embeddings estão disponíveis na estrutura
*   embeddings_output
* - O breakpoint permite inspecionar os resultados durante a execução
* - Na prática, esses vetores podem ser armazenados em tabelas para 
*   posterior comparação ou uso em algoritmos de machine learning
*----------------------------------------------------------------------*
      BREAK-POINT.  "Permite inspecionar os embeddings gerados durante a execução

*----------------------------------------------------------------------*
* TRATAMENTO DE EXCEÇÕES: Captura e exibe erros que possam ocorrer
* - Problemas de conexão, autenticação ou com a API são tratados aqui
*----------------------------------------------------------------------*
    CATCH zcx_peng_azoai_sdk_exception INTO DATA(ex).  "Exceção específica do SDK OpenAI
      MESSAGE ex TYPE 'I'.  "Exibe mensagem de erro informativa
  ENDTRY.
