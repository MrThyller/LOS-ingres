#!/usr/bin/env bash
#-------------------------------------------------------------------#
# Autor       : WhoFoss <https://github.com/WhoFoss>
# Programa    : gofile_upload.sh
# DESCRIÇÃO   :
# Script utilitário para enviar um arquivo (ex: ROM compilada) para o
# GoFile e exibir o link de download e tamanho opcional.
#
# Dependências:
#   - curl
#   - jq
#
# Recursos:
#   - Seleção automática de servidor GoFile
#   - Upload do arquivo e extração do link de download
#   - Exibição de nome e tamanho
#
#-------------------------------------------------------------------#

#####################################
#----------------------------------#
# Funções
#----------------------------------#
#####################################

# Envia o arquivo para o GoFile e retorna o link de download.
upload_gofile() {
    local FILE="$1"

    if [ ! -f "$FILE" ]; then
        echo "[ERRO] Arquivo nao encontrado: $FILE"
        return 1
    fi

    SERVER=$(curl -ks https://api.gofile.io/servers | jq -r '.data.servers[0].name')

    if [[ -z "$SERVER" || "$SERVER" == "null" ]]; then
        echo "[ERRO] Nao foi possivel obter servidor GoFile"
        return 1
    fi

    LINK=$(curl -k# -F "file=@$FILE" \
        "https://${SERVER}.gofile.io/uploadFile" | jq -r '.data.downloadPage')

    if [[ -z "$LINK" || "$LINK" == "null" ]]; then
        echo "[ERRO] Upload falhou"
        return 1
    fi

    echo "$LINK"
}

#####################################
#----------------------------------#
# Main
#----------------------------------#
#####################################

# Valida os argumentos, dispara o upload e exibe o resultado.
main() {
    if [[ "$#" == '0' ]]; then
        echo "[ERRO] Nenhum arquivo especificado"
        echo "Uso: $0 /caminho/para/arquivo.zip"
        exit 1
    fi

    FILE="$1"

    FILE_NAME=$(basename "$FILE")
    FILE_SIZE=$(du -h "$FILE" | cut -f1)

    DOWNLOAD_LINK=$(upload_gofile "$FILE")

    if [ $? -eq 0 ] && [ -n "$DOWNLOAD_LINK" ]; then
        echo "[OK] Nome: $FILE_NAME"
        echo "[OK] Tamanho: $FILE_SIZE"
        echo "[OK] Download: $DOWNLOAD_LINK"
    else
        echo "[ERRO] Falha no upload"
        exit 1
    fi
}

main "$@"
