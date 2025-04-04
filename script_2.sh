#!/bin/bash

# Variáveis para melhor legibilidade e fácil modificação
OPENBOX_CONFIG_DIR="$HOME/.config/openbox"
MENU_FILE="menu.xml"
BACKUP_PREFIX="menu_backup_"
NEW_MENU_FILE="$OPENBOX_CONFIG_DIR/$MENU_FILE"
BACKUP_MENU_FILE="$OPENBOX_CONFIG_DIR/${BACKUP_PREFIX}$(date +%Y%m%d%H%M%S).xml"
RESCUE_CALLINGCARD_PACKAGE="rescue-callingcard"
GOTO_KEYRING_URL="https://packages.goto.com/goto-keyring"
GOTO_KEYRING_PATH="/usr/share/keyrings/goto-keyring.gpg"
GOTO_DEB_LINE="deb [signed-by=${GOTO_KEYRING_PATH}] https://packages.goto.com/deb stable main"
GOTO_LIST_FILE="/etc/apt/sources.list.d/goto.list"
CALLINGCARD_CONFIG_DIR="/opt/rescue-callingcard/bin"
CALLINGCARD_CONFIG_FILE="${CALLINGCARD_CONFIG_DIR}/.callingcard"
CALLINGCARD_URL="https://secure.logmeinrescue.com/CallingCard/CallingCardCustomization.aspx?company_id=3394892&channel_id=6063156&lmi_os=linux"

# Cores para saída no terminal
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Iniciando script...${NC}"

# 1. Backup do arquivo de menu do Openbox
if [ -f "$NEW_MENU_FILE" ]; then
  mv "$NEW_MENU_FILE" "$BACKUP_MENU_FILE"
  echo "Arquivo $MENU_FILE já existente renomeado para $(basename "$BACKUP_MENU_FILE")"
fi

# 2. Copia o novo arquivo de menu
echo -e "${YELLOW}Copiando o arquivo $MENU_FILE para $OPENBOX_CONFIG_DIR...${NC}"
if cp "$MENU_FILE" "$OPENBOX_CONFIG_DIR"; then
  echo -e "${GREEN}Arquivo $MENU_FILE copiado com sucesso para $OPENBOX_CONFIG_DIR${NC}"
else
  echo -e "${RED}Erro ao copiar o arquivo $MENU_FILE para $OPENBOX_CONFIG_DIR. Saindo...${NC}" >&2
  exit 1
fi

# 3. Aplica permissões no arquivo de menu
echo -e "${YELLOW}Aplicando permissões de execução no arquivo $NEW_MENU_FILE...${NC}"
if chmod +x "$NEW_MENU_FILE"; then
  echo -e "${GREEN}Permissões de execução aplicadas com sucesso em $NEW_MENU_FILE${NC}"
else
  echo -e "${RED}Erro ao aplicar permissões de execução em $NEW_MENU_FILE. Verifique as permissões do diretório.${NC}" >&2
fi

# 4. Instalação do rescue-callingcard
echo -e "${GREEN}Iniciando instalação do $RESCUE_CALLINGCARD_PACKAGE${NC}"

# Verifica se o wget está instalado e instala se necessário
if ! command -v wget &> /dev/null; then
  echo -e "${YELLOW}Wget não encontrado. Iniciando instalação...${NC}"
  sudo apt-get update && sudo apt-get install --yes wget
  if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao instalar o wget. A instalação do $RESCUE_CALLINGCARD_PACKAGE pode falhar. Saindo...${NC}" >&2
    exit 1
  fi
else
  echo -e "${YELLOW}Wget já instalado.${NC}"
fi

# Adiciona a chave e o repositório do GoTo
echo -e "${YELLOW}Adicionando chave e repositório do GoTo...${NC}"
wget --quiet --output-document - "$GOTO_KEYRING_URL" | gpg --dearmor --yes --output "$GOTO_KEYRING_PATH"
if [ $? -ne 0 ]; then
  echo -e "${RED}Erro ao baixar e adicionar a chave do GoTo. Saindo...${NC}" >&2
  exit 1
fi

echo "$GOTO_DEB_LINE" | sudo tee "$GOTO_LIST_FILE" > /dev/null
if [ $? -ne 0 ]; then
  echo -e "${RED}Erro ao adicionar o repositório do GoTo. Verifique as permissões do arquivo $GOTO_LIST_FILE. Saindo...${NC}" >&2
  exit 1
fi

# Atualiza a lista de pacotes e instala o rescue-callingcard
echo -e "${YELLOW}Atualizando lista de pacotes e instalando $RESCUE_CALLINGCARD_PACKAGE...${NC}"
sudo apt-get update && sudo apt-get install --yes "$RESCUE_CALLINGCARD_PACKAGE"
if [ $? -ne 0 ]; then
  echo -e "${RED}Erro ao instalar o pacote $RESCUE_CALLINGCARD_PACKAGE. Verifique sua conexão com a internet e se o repositório do GoTo está correto.${NC}" >&2
  exit 1
fi
echo -e "${GREEN}Instalação do $RESCUE_CALLINGCARD_PACKAGE concluída com sucesso.${NC}"

# 5. Cria o arquivo de configuração para o CallingCard
echo -e "${YELLOW}Criando o arquivo de configuração para o CallingCard em $CALLINGCARD_CONFIG_FILE...${NC}"
mkdir -p "$CALLINGCARD_CONFIG_DIR" # Garante que o diretório existe
echo "$CALLINGCARD_URL" | tee "$CALLINGCARD_CONFIG_FILE"
if [ $? -ne 0 ]; then
  echo -e "${RED}Erro ao criar o arquivo de configuração do CallingCard em $CALLINGCARD_CONFIG_FILE. Verifique as permissões do diretório.${NC}" >&2
fi
echo -e "${GREEN}Arquivo de configuração do CallingCard criado com sucesso em $CALLINGCARD_CONFIG_FILE.${NC}"

echo -e "${GREEN}Script concluído com sucesso!${NC}"

exit 0