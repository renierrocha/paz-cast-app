// Google Apps Script para inserir dados na planilha de relatórios de célula
// ID da planilha: 1hRmGeYYvKyxHJw2NpLNMRAK2ThqLkUo0SwfEy12otc4
// Aba: Células

function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);

    // Verifica se os dados necessários estão presentes
    if (!data.spreadsheetId || !data.sheetName || !data.data) {
      return ContentService
        .createTextOutput(JSON.stringify({success: false, error: 'Dados incompletos'}))
        .setMimeType(ContentService.MimeType.JSON);
    }

    // Abre a planilha
    const spreadsheet = SpreadsheetApp.openById(data.spreadsheetId);
    const sheet = spreadsheet.getSheetByName(data.sheetName);

    if (!sheet) {
      return ContentService
        .createTextOutput(JSON.stringify({success: false, error: 'Aba não encontrada'}))
        .setMimeType(ContentService.MimeType.JSON);
    }

    // Prepara os dados para inserção baseado na aba
    let rowData;
    if (data.sheetName === 'Células') {
      // Formato para relatórios de célula
      rowData = [
        data.data.data || '', // Data da reunião
        data.data.lider || '', // Líder
        data.data.membros_presentes || 0, // Membros presentes
        data.data.convidados || 0, // Convidados
        data.data.criancas || 0, // Crianças
        data.data.ofertas || 0, // Ofertas
        data.data.supervisao ? 'Sim' : 'Não', // Supervisão
        data.data.observacoes || '', // Observações
        data.data.user_name || '', // Nome do usuário
        new Date().toLocaleString('pt-BR') // Timestamp
      ];
    } else if (data.sheetName === 'Volts') {
      // Formato para check-in/check-out
      const itens = data.data.itens || {};
      rowData = [
        data.data.timestamp ? new Date(data.data.timestamp.seconds * 1000).toLocaleString('pt-BR') : new Date().toLocaleString('pt-BR'), // Timestamp
        data.data.nome || '', // Nome do Membro
        data.data.ministerio || '', // Ministério
        itens.cracha ? 'Sim' : 'Não', // Crachá
        itens.cordao ? 'Sim' : 'Não', // Cordão
        itens.equipamento ? 'Sim' : 'Não', // Equipamento
        data.data.situacao || 'Em uso', // Situação
        data.data.tipo || 'checkin', // Tipo (checkin/checkout)
      ];
    } else {
      return ContentService
        .createTextOutput(JSON.stringify({success: false, error: 'Aba não suportada'}))
        .setMimeType(ContentService.MimeType.JSON);
    }

    // Adiciona a linha na planilha
    sheet.appendRow(rowData);

    return ContentService
      .createTextOutput(JSON.stringify({success: true, message: 'Dados inseridos com sucesso'}))
      .setMimeType(ContentService.MimeType.JSON);

  } catch (error) {
    return ContentService
      .createTextOutput(JSON.stringify({success: false, error: error.toString()}))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

// Função de teste (opcional)
function testInsert() {
  const testData = {
    spreadsheetId: '1hRmGeYYvKyxHJw2NpLNMRAK2ThqLkUo0SwfEy12otc4',
    sheetName: 'Células',
    data: {
      data: '15/12/2024',
      lider: 'João Silva',
      membros_presentes: 10,
      convidados: 2,
      criancas: 3,
      ofertas: 150.50,
      supervisao: true,
      observacoes: 'Reunião muito boa!',
      user_name: 'Test User'
    }
  };

  return doPost({postData: {contents: JSON.stringify(testData)}});
}