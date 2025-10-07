# README — scan.ps1

Script PowerShell 5+ para checar porta TCP (padrão 5432) em uma lista de hosts sem usar nmap.

## O que faz
- Lê `hosts.txt`, remove linhas vazias e comentários (`#`).
- Para cada host tenta conectar na porta (padrão `$port = 5432`) usando `System.Net.Sockets.TcpClient`.
- Retorna por host: `Target`, `Port`, `Open` (True/False) e `TimeMs` (ms de resposta).
- Exporta todos os resultados para `scan_5432_results.csv`.
- Imprime no console apenas os hosts com porta aberta.

## Requisitos
- Windows PowerShell 5.x ou superior.
- Permissão de execução de scripts (`ExecutionPolicy`).
- `hosts.txt` no mesmo diretório do script ou fornecido por caminho.

## Formato de `hosts.txt`
Um host por linha (IP ou nome). Linhas vazias ou que começam com `#` são ignoradas.
```
# Exemplo
192.0.2.1
exemplo.local
# comentário
```

## Uso
Execute no prompt do PowerShell:
```powershell
powershell -ExecutionPolicy Bypass -File .\scan.ps1
```
Ou abra o PowerShell e rode:
```powershell
.\scan.ps1
```

## Parâmetros e ajustes rápidos
- Mudar porta: editar a variável `$port` no início do script.
- Timeout: alterar `-TimeoutMs` passado para `Test-TcpPort`. Padrão 3000 ms.
- Paralelismo: o script é sequencial. Para muitos hosts use PowerShell 7+ e paralelize com `ForEach-Object -Parallel` ou reimplemente com jobs/threads.

## Saída
- `scan_5432_results.csv` com todos os registros.
- No console uma tabela apenas com hosts onde `Open` é `True`.

## Observações técnicas
- Conexões são tentadas com `TcpClient.BeginConnect` e aguardam `TimeoutMs`.
- Falhas ou exceções são tratadas e retornam `Open = $false`.
- Não realiza varredura furtiva nem identifica serviços além de checar a porta TCP.
- Para auditoria de rede em escala use ferramentas específicas (nmap, masscan) ou paralelize o script.

---

# README — Resolve-FromFile.ps1 (exemplos de uso)

Script para resolver nomes DNS a partir de arquivo de hosts. Suporta opção `-DnsServer`.

## Exemplos
Resolver usando o DNS configurado no sistema:
```powershell
.\Resolve-FromFile.ps1 -File .\hosts.txt
```

Resolver usando o DNS público do Google:
```powershell
.\Resolve-FromFile.ps1 -File .\hosts.txt -DnsServer 8.8.8.8
```

## Notas
- `-File` aponta para o arquivo com nomes/hosts, mesmo formato (uma entrada por linha).
- Se `-DnsServer` não for passado usa-se o(s) DNS configurado(s) do sistema.
- Verifique permissões e ExecutionPolicy se o script não rodar diretamente.

---

# Exemplos práticos
1. Rodar scan e ver resultados:
```powershell
powershell -ExecutionPolicy Bypass -File .\scan.ps1
Import-Csv .\scan_5432_results.csv | Where-Object {$_.Open -eq "True"}
```

2. Resolver nomes antes de scan (fluxo sugerido):
```powershell
.\Resolve-FromFile.ps1 -File .\hosts.txt -DnsServer 8.8.8.8 > resolved_hosts.txt
# editar resolved_hosts.txt para ficar um host por linha
.\scan.ps1
```

## Licença / Aviso de uso
Use com responsabilidade. Teste apenas redes e hosts que você tem autorização para testar.
