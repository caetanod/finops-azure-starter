# Política de Segurança

## Versões suportadas

| Versão | Suporte de segurança |
|--------|---------------------|
| 0.1.x  | :white_check_mark: Sim |

## Reportando uma vulnerabilidade

Se você encontrou uma vulnerabilidade de segurança neste projeto, **não abra uma Issue pública**.

Envie um e-mail para: **diego.caetano@nstech.com.br**

Inclua:
- Descrição da vulnerabilidade
- Passos para reproduzir
- Impacto potencial

Você receberá uma resposta em até **5 dias úteis**. Se a vulnerabilidade for confirmada, publicaremos um advisory de segurança e criaremos um patch o mais breve possível.

## Escopo

Este projeto é um kit de scripts e documentação — não há servidor, banco de dados ou serviço hospedado. As principais superfícies de risco são:

- **Scripts PowerShell / Bash**: command injection, exposição acidental de credenciais
- **Credenciais Azure**: os scripts usam `az login` via Azure CLI e nunca devem receber senhas em texto plano como parâmetro

## Boas práticas para usuários

- Nunca commite arquivos `.env` ou qualquer arquivo contendo chaves de acesso
- Use Azure RBAC com o princípio do menor privilégio (veja [prerequisites.md](docs/prerequisites.md))
- Valide o `az account show` antes de executar os scripts em ambientes de produção
- Revise os scripts antes de executar em uma assinatura de produção

## Reconhecimento

Agradecemos o reporte responsável de vulnerabilidades. Contribuidores que reportarem problemas válidos serão reconhecidos nas release notes (a menos que prefiram anonimato).
