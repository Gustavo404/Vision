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