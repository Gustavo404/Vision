#!/bin/bash

# Variaveis misselaneas
# SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
dir_tsunami="../permutador.sh"
dir_oxygen="../vision.expect"
dir_obsidian="../obsidian/obsidian.sh"

# Função para mostrar mensagens coloridas
function color_message() {
  local color=$1
  local message=$2
  case $color in
    "red")
      echo -e "\e[91m$message\e[0m"
      ;;
    "green")
      echo -e "\e[92m$message\e[0m"
      ;;
    "blue")
      echo -e "\e[94m$message\e[0m"
      ;;
    "yellow")
      echo -e "\e[93m$message\e[0m"
      ;;
    *)
      echo "$message"
      ;;
  esac
}

# Função para coletar dados de entrada do usuário
coletar_dados() {
    color_message "yellow" "[?] Digite o nome do arquivo de entrada: "
    read input
    color_message "yellow" "[?] Digite o IP do servidor Telnet: "
    read ip
    color_message "yellow" "[?] Digite o usuário do servidor Telnet: "
    read user
    color_message "yellow" "[?] Digite a senha do servidor Telnet: "
    read pass
}

# Função para processar as opções da linha de comando
processar_opcoes() {
    while getopts "i:u:p:s:" opt; do
        case $opt in
            s) ip="$OPTARG" ;;
            u) user="$OPTARG" ;;
            i) input="$OPTARG" ;;
            p) pass="$OPTARG" ;;
            \?)
                color_message "red" "[!] Opção inválida: -$OPTARG" >&2
                color_message "yellow" "[?] Uso: bash vision.sh -s SERVER_IP -u USER -i INPUT_FILE -p PASS"
                exit 1
                ;;
            :)
                color_message "red" "[!] A opção -$OPTARG requer um argumento." >&2
                color_message "yellow" "[?] Uso: bash vision.sh -s SERVER_IP -u USER -i INPUT_FILE -p PASS"
                exit 1
                ;;
        esac
    done
}

# Função para verificar se todas as variáveis foram preenchidas
verificar_variaveis() {
    if [[ -z "$input" || -z "$ip" || -z "$user" || -z "$pass" ]]; then
        color_message "yellow" "[?] Uso: bash vision.sh -s SERVER_IP -u USER -i INPUT_FILE -p PASS"
        exit 1
    fi
}

# Função para verificar se o arquivo de entrada existe
verificar_arquivo() {
    if [[ ! -f "$input" ]]; then
        color_message "red" "[!] O arquivo $input não existe"
        color_message "yellow" "[?] Uso: bash vision.sh -s SERVER_IP -u USER -i INPUT_FILE -p PASS"
        exit 1
    fi
}

# Função para criar uma pasta de saída usando o nome do input a fim de organizar arquivos em multi processamentos
criar_pasta_saida() {
    input_sem_extensao=$(basename "$input" | cut -f 1 -d '_')
    input_sem_extensao=$(basename "$input_sem_extensao" | cut -f 1 -d '.')
    # Verifica se o diretório existe
    if [ -d "$input_sem_extensao" ]; then
        cp $input "$input_sem_extensao"/
        cd "$input_sem_extensao" || exit 1
    else
        mkdir "$input_sem_extensao"
        cp $input "$input_sem_extensao"/
        cd "$input_sem_extensao" || exit 1
    fi
}

# Função para verificar o padrão da primeira linha do arquivo
verificar_padrao() {
    # Lê a primeira linha do arquivo de entrada
    local first_line=$(head -n 1 "$input")

    # Verifica se a primeira linha corresponde a um dos padrões usando o comando grep
    if echo "$first_line" | grep -E '^[0-9]+\s+[0-9]+\s+[0-9]+$'; then
        echo
        color_message "blue" "[!] O arquivo $input está no padrão '1 2 3': $first_line"
        converter_arquivo
        local first_line=$(head -n 1 "$input")
    fi
    if echo "$first_line" | grep -E '^[0-9]+\/[0-9]+\/[0-9]+$'; then
        echo
        color_message "blue" "[!] O arquivo $input está no padrão '1/2/3': $first_line"
        converter_arquivo_telnet
        local first_line=$(head -n 1 "$input")
    fi
        color_message "yellow" "[?] Deseja executar o Oxygen para: $first_line? (S/n)"
        read resposta
        if [[ -z "$resposta" || "$resposta" =~ ^[SsYy]$ ]]; then
            executar_oxygen
        fi
}

# Função para converter o arquivo de "1 2 3" para "1/2/3"
converter_arquivo() {
    color_message "yellow" "[?] Deseja converter $input de '1 2 3' para '1/2/3'? (S/n)"
    read resposta
    if [[ -z "$resposta" || "$resposta" =~ ^[SsYy]$ ]]; then
        bash $dir_tsunami -i "$input"
        input_sem_extensao=$(basename "$input" | cut -f 1 -d '_')
        input_sem_extensao=$(basename "$input_sem_extensao" | cut -f 1 -d '.')
        input="${input_sem_extensao}_formatado.txt"
        echo
    fi
}

# Função para converter o arquivo de "1/2/3" para comandos Telnet
converter_arquivo_telnet() {
    color_message "yellow" "[?] Deseja converter $input de '1/2/3' para comandos Telnet? (S/n)"
    read resposta
    if [[ -z "$resposta" || "$resposta" =~ ^[SsYy]$ ]]; then
        bash $dir_tsunami -t "$input"
        input_sem_extensao=$(basename "$input" | cut -f 1 -d '_')
        input_sem_extensao=$(basename "$input_sem_extensao" | cut -f 1 -d '.')
        input="${input_sem_extensao}_comandos.txt"
        echo
    fi
}

# Função para executar o Oxygen
executar_oxygen() {
    expect $dir_oxygen "$ip" "$user" "$pass" "$input" | tee "$input_sem_extensao"_telnet.txt
    grep -E 'RECV POWER   :|onu is in unactive!|\[ ERR ' "$input_sem_extensao"_telnet.txt > "$input_sem_extensao"_recv.txt
    echo
    color_message "green" "Oxygen executado com sucesso"
    echo
}

# Função para filtrar os dados
filtrar_dados() {
    color_message "yellow" "[!] Iniciando formatação dos dados com Tsunami"
    
    
    cat "$input_sem_extensao"_telnet.txt | grep '\(-40\|SEND POWER   :\|\[ ERR\)' > tmp.tmp
    sed -e 's/(Dbm)//g; s/\t(Dbm)//g; s/POWER//g; s/   / /g; s/  / /g; s/ onu is in unactive!//g' tmp.tmp > "$input_sem_extensao"_send.txt

    cat "$input_sem_extensao"_telnet.txt | grep '\(-40\|RECV POWER   :\|\[ ERR\)' > tmp.tmp
    sed -e 's/(Dbm)//g; s/\t(Dbm)//g; s/POWER//g; s/   / /g; s/  / /g; s/ onu is in unactive!//g' tmp.tmp > "$input_sem_extensao"_recv.txt

    cat "$input_sem_extensao"_telnet.txt | grep '\(-40\|OLT RECV POWER :\|\[ ERR\)' > tmp.tmp
    sed -e 's/(Dbm)//g; s/\t(Dbm)//g; s/POWER//g; s/   / /g; s/  / /g; s/ onu is in unactive!//g' tmp.tmp > "$input_sem_extensao"_olt_recv.txt

    rm tmp.tmp
    echo
}

# Coleta de dados
if [[ $# -eq 0 ]]; then
    coletar_dados
else
    processar_opcoes "$@"
fi

# Banner
clear
cat .banner | lolcat
echo

current_dir=$(pwd)
color_message "green" "[!] Diretório atual: $current_dir" && echo

# Verificação de variáveis
verificar_variaveis
verificar_arquivo
criar_pasta_saida

# Conversão de quebra de linha de Dos para Unix
color_message "yellow" "[!] Convertendo quebra de linha para Unix..."
dos2unix "$input" 2> /dev/null
echo

# Verificação de padrão
verificar_padrao

# Filtragem de dados
filtrar_dados

# Função de limpar o diretório desligada
# color_message "yellow" "[?] Deseja apagar os arquivos 'recv' e 'comandos'? (S/n)"
# read resposta
# if [[ -z "$resposta" || "$resposta" =~ ^[SsYy]$ ]]; then
#     # rm "$input_sem_extensao"_telnet.txt
#     rm "$input_sem_extensao"_recv.txt
#     # rm "$input_sem_extensao"_formatado.txt
#     rm "$input_sem_extensao"_comandos.txt
#     # rm "$input_sem_extensao"_sinal.txt
# fi

# Finalização do script
echo
color_message "yellow" "[!] Finalizando..."

# pr -T -s$'\t' -m -w100 -t ../"$input_sem_extensao"_formatado.txt "$input_sem_extensao"_send.txt "$input_sem_extensao"_recv.txt "$input_sem_extensao"_olt_recv.txt | column -s $'\t' -t

export ARQUIVO1=../"$input_sem_extensao"_formatado.txt
export ARQUIVO2="$input_sem_extensao"_send.txt
export ARQUIVO3="$input_sem_extensao"_recv.txt
export ARQUIVO4="$input_sem_extensao"_olt_recv.txt

python3 - <<EOF
import pandas as pd
from io import StringIO
import os

# Ler os arquivos como DataFrames do Pandas
df1 = pd.read_csv(StringIO(open(os.environ['ARQUIVO1']).read()), sep='\t', header=None)
df2 = pd.read_csv(StringIO(open(os.environ['ARQUIVO2']).read()), sep='\t', header=None)
df3 = pd.read_csv(StringIO(open(os.environ['ARQUIVO3']).read()), sep='\t', header=None)
df4 = pd.read_csv(StringIO(open(os.environ['ARQUIVO4']).read()), sep='\t', header=None)

# Concatenar os DataFrames ao longo das colunas
result = pd.concat([df1, df2, df3, df4], axis=1)

# Preencher os valores ausentes com uma string vazia
result = result.fillna('')

# Configurar a largura da coluna manualmente
col_width = 10
pd.set_option('display.max_colwidth', col_width)

# Alinhar o texto à esquerda
result = result.apply(lambda x: x.map(lambda y: str(y).ljust(col_width)))

# Configurar a largura da coluna novamente para que a formatação funcione corretamente
pd.set_option('display.max_colwidth', None)

# Configurar a largura da coluna e centralizar o texto
pd.set_option('display.max_colwidth', None)
pd.set_option('display.colheader_justify', 'center')

# Imprimir o resultado
print(result.to_string(index=False, header=False))
EOF



color_message "green" "[.]Script finalizado"

exit 0
