# Configuração do Sistema Paz Castanhal

## Funcionalidades Implementadas

### 1. Relatório de Célula
- Campos: Data, Líder, Membros presentes, Convidados, Crianças, Ofertas, Supervisão, Observações
- Integração com aba "Células" da planilha

### 2. Check-in/Check-out (Volts)
- **Campos na planilha:**
  - Timestamp do Check-in
  - Nome do Membro
  - Ministério
  - Crachá (Sim/Não)
  - Cordão (Sim/Não)
  - Equipamento (Sim/Não)
  - Situação (Em uso / Checkout OK)

- **Funcionalidades:**
  - Check-in com seleção de itens para empréstimo
  - Check-out com validação de itens devolvidos
  - Lista de membros que ainda precisam fazer check-out
  - Integração com aba "Volts" da planilha

## Configuração da Planilha Google

### Preparar a Planilha
1. Criar/abrir planilha: `1hRmGeYYvKyxHJw2NpLNMRAK2ThqLkUo0SwfEy12otc4`

### Aba "Células" (Relatórios)
1. Criar aba chamada "Células"
2. Cabeçalhos na linha 1:
   ```
   A1: Data da Reunião
   B1: Líder
   C1: Membros Presentes
   D1: Convidados
   E1: Crianças
   F1: Ofertas
   G1: Supervisão
   H1: Observações
   I1: Enviado por
   J1: Data/Hora Envio
   ```

### Aba "Volts" (Check-in/Check-out)
1. Criar aba chamada "Volts"
2. Cabeçalhos na linha 1:
   ```
   A1: Timestamp Check-in
   B1: Nome do Membro
   C1: Ministério
   D1: Crachá
   E1: Cordão
   F1: Equipamento
   G1: Situação
   H1: Tipo
   ```

## Configuração do Google Apps Script

### 1. Criar Script
1. Acesse [script.google.com](https://script.google.com)
2. Criar novo projeto
3. Substituir código pelo conteúdo de `google_apps_script.js`

### 2. Publicar
1. **Publicar** → **Implantar como aplicativo da web**
2. Configurar:
   - Executar como: Você
   - Acesso: Qualquer pessoa (anônima)
3. **Implantar** e copiar URL

### 3. Atualizar Código Flutter
Substituir no `lib/main.dart`:
```dart
const String scriptUrl = 'SUA_URL_AQUI';
```

## Como Usar

### Relatório de Célula
1. Menu **Membro** → **Relatório de Célula**
2. Preencher formulário
3. Enviar (dados vão para aba "Células")

### Check-in/Check-out
1. Menu **Membro** → **Acesso Restrito** → **Check-in/Check-out**
2. Escanear QR do membro
3. Selecionar itens para empréstimo
4. Confirmar check-in
5. Para check-out: escanear novamente → confirmar devolução

## Testes

### Testar Relatórios
```bash
dart run teste_planilha.dart
```

### Testar Check-in/Check-out
```bash
dart run teste_volts.dart
```

## Tratamento de Erros

- Dados sempre salvos no Firestore primeiro
- Se falhar na planilha, mostra aviso mas não bloqueia
- Check-outs pendentes ficam visíveis na interface</content>
<parameter name="filePath">c:\dev\paz_castanhal\README_RELATORIO_CELULA.md