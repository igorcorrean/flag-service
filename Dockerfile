# ==============================================================================
# ESTÁGIO 1: Builder (Instalação e Isolamento de Dependências)
# ==============================================================================
FROM python:3.11-alpine AS builder

# Configurações para otimizar o Python no ambiente Docker
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Instala ferramentas de compilação caso alguma dependência precise compilar código C
RUN apk add --no-cache gcc musl-dev postgresql-dev

# Copia apenas o arquivo de dependências para aproveitar o cache de camadas do Docker
COPY requirements.txt .

# Instala as dependências isolando-as no diretório do usuário local
RUN pip install --no-cache-dir --user -r requirements.txt


# ==============================================================================
# ESTÁGIO 2: Run (Ambiente de Execução Final Otimizado)
# ==============================================================================
FROM python:3.11-alpine AS runner

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH=/root/.local/bin:$PATH

WORKDIR /app

# Instala apenas a biblioteca de runtime necessária para o driver do PostgreSQL
RUN apk add --no-cache libpq

# Copia apenas os pacotes instalados no estágio anterior (sem ferramentas de build)
COPY --from=builder /root/.local /root/.local

# Copia o código-fonte da aplicação para o diretório de trabalho
COPY . .

# Expõe a porta definida no README para comunicação interna
EXPOSE 8002

# Executa o Gunicorn no formato de array (essencial para tratamento de sinais pelo Kubernetes)
# O bind utiliza a porta 8002 padrão informada na documentação do serviço
CMD ["gunicorn", "--bind", "0.0.0.0:8002", "app:app"]