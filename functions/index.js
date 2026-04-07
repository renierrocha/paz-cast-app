const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { google } = require('googleapis');

admin.initializeApp();

// 1. COLE O ID DA SUA PLANILHA AQUI (Fica na URL entre /d/ e /edit)
const SPREADSHEET_ID = 'COLE_AQUI_O_ID_DA_SUA_PLANILHA';

// 2. COLE OS DADOS DO SEU ARQUIVO JSON AQUI
const serviceAccount = {
  "project_id": "pazcastanhal-809cd",
  "client_email": "sheets-sync@pazcastanhal-809cd.iam.gserviceaccount.com",
  "private_key": "nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDG4Tyn8/mqApyg\n8WrSt2oS0lqt92SG2dgTjt7jhqTFvTRQOooFPuwbgyeZzT3nvTt5sJPPK3wiHCCe\n3ZQNN80vxtZncftKKWWwIbygP+zXRxgTeI4g2izBJnw0LaPdpp8dyX9YnIwKWqRH\n+E/JKokoaSPZYd069EbkE6RUzm+7XUCWCsHYYxwr9vPv7p/2nAs8bOb/4xQtL46B\nflhY7h6nSv5b9MzxIIovXMTZJFIseJEJtfjLdAbZwp0btcicT0aDWRTVA8hp1Alm\ncBxKtU35CQUjtXiONL1nGN3Hqf6AsOAqYqlzBx66BbS0sXxIDMlga4k/OkKrtyr9\nOXIK3nJTAgMBAAECggEAQFcJ2oQRlzC1H1Q67OStil1HPNS2TvIW92zXKuCaWeZ2\nECaAFGZg2B28KAPALUKJBTtc9j7pL9fNrdedWBFfbj9ziY/Ubg+qeCrR7T4BDzxO\ny63KvVIX/HzI3dCOHN0UyPwxGKe8nnTohOgOV9RM/yfUkzUX70Sr0omQNmd6ujBE\n9+DeU/teskKWR4U1u3Xc7qdosFchl4zMzbl+SBDtKVdLUX0vzxnHx41OOW+lt22J\nq4XvkzNoKn6AfS9Hcz9Is9+Ftzejnlhre+N/h0dfz4qohfYAqgbqc4mmv4GNgVbc\nCCPNXYAAgWkLVveLTWdZsviPlC3KPCvDaC3aY2Ul8QKBgQDmTHK+8a8vXYR3Lz11\nSB1FkzfK4L1JFBFvmuoF5OZl2Q3GEdztHVMWHZFtQPwQb0vEtSymoPSscU86o25t\nL1+uZJOpBRxPjj13iHaNcwVpVh7XYO9ERqzsSO6rb1zGlUC4ldIC1AuuoE80wzs+\nDkD24d6Pb+9dRwJW4Pq2PzNvJwKBgQDdEyooFHGtUvWoBpvN3sX1J7fb0Rnv6qag\n+7S0kxhMFclAAe5SrMiENXkSA1rPZ/zNL8+g7Nu0jmFVbu+eC5uhQjHOKSQr9/Ze\nnrGHkHxlHtDew1jytyaWrC6QagXrW45S6kVJ8mY5JSov3bjE9sBpJ2tOUjXI/roA\nYCLJZn2e9QKBgAnscWVY9LuNxA9+sZ9EJD7DQTw0wvNLMhUlD8CBRIxO9hD65BIz\nmUjyrTmP+0yZ/yHSzMHBXcmweEGGmVOLHwxcuSAnYDjtYCiucK1Xr3wCggG145mF\nkh38ZoxsmArWk5tgmVQV3wr/TWpwnzTlWFdLFFQJ9r6GOMuVljgUMRsxAoGAPEDq\n7n2T9g90UNVsRZIAFi87FzhIf3FO9PVlbQniR2pwrXdZQ0NAa3g/hT9Q0tKevjXX\nux6TSwS7VpOjz0mOo0btWCkyaKFujp9l93LT1KOvfed0KMLuS4amMkoTTvBnPAYJ\n2HuujMiqVN1zbItsKbzKrFAPxLZYb53EHWxHtLkCgYALLbhg+M4a0UwdH0lFiZJN\n0HFBwDins1Zjw5w3vo4IZfonin6u1gYNCWnxP2FtHL1jUouFjkqSXBpo7TqdOd7g\nMFr6RTmlNt2T/4ge7wlvuGpRN4NSvuL3c06TM52hU46JZ5jwYccMFWMAjdU3p1fV\ns/kJa07vy9bC0WfRv2gXew=="
};

const auth = new google.auth.JWT(
    serviceAccount.client_email,
    null,
    serviceAccount.private_key,
    ['https://www.googleapis.com/auth/spreadsheets']
);
const sheets = google.sheets({ version: 'v4', auth });

// FUNÇÃO PARA RELATÓRIOS DE CÉLULA
exports.syncRelatorioToSheets = functions.firestore
    .document('relatorios_celula/{reportId}')
    .onCreate(async (snap, context) => {
        const data = snap.data();
        
        // Prepara a linha exatamente com os nomes que usamos no App v43.0
        const row = [
            new Date().toLocaleString('pt-BR'), // A: Data
            data.celula || "",                 // B: Nome da Célula
            data.lider || "",                  // C: Líder
            data.enviadoPor || "",             // D: Responsável pelo Envio
            data.presenca || 0,                // E: Membros
            data.convidados || 0,              // F: Convidados
            data.oferta || "0.00",             // G: Oferta
            data.supervisao || "Não",          // H: Supervisão
            data.observacoes || ""             // I: Observações
        ];

        try {
            await sheets.spreadsheets.values.append({
                spreadsheetId: SPREADSHEET_ID,
                range: 'Página1!A:I', // Verifique se o nome da aba é exatamente este
                valueInputOption: 'USER_ENTERED',
                resource: { values: [row] },
            });
            console.log('Sucesso: Relatório enviado para a planilha.');
        } catch (err) {
            console.error('ERRO AO ENVIAR PARA PLANILHA:', err.message);
        }
        return null;
    });

// FUNÇÃO DE NOTIFICAÇÃO PUSH (Mantida)
exports.enviarNotificacaoAviso = functions.firestore
    .document('avisos/{avisoId}')
    .onCreate(async (snap, context) => {
        const dados = snap.data();
        const mensagem = {
            notification: { title: dados.titulo, body: dados.descricao },
            topic: 'todos',
        };
        return admin.messaging().send(mensagem);
    });

// FUNÇÃO PARA RESET MENSAL DO DESAFIO DA BÍBLIA
exports.monthlyBibleChallengeReset = functions.pubsub.schedule('0 0 1 * *').timeZone('America/Sao_Paulo').onRun(async (context) => {
    const db = admin.firestore();
    
    // Calcular mês anterior
    const now = new Date();
    const prevMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const prevMKey = `${prevMonth.getFullYear()}-${prevMonth.getMonth() + 1}`;
    
    console.log(`Archiving Bible challenge data for month: ${prevMKey}`);
    
    // Buscar dados do mês anterior
    const rankingRef = db.collection('ranking');
    const snapshot = await rankingRef.where('month', '==', prevMKey).get();
    
    if (!snapshot.empty) {
        const batch = db.batch();
        snapshot.docs.forEach(doc => {
            // Arquivar em ranking_archive
            const archiveRef = db.collection('ranking_archive').doc();
            batch.set(archiveRef, { 
                ...doc.data(), 
                archivedAt: admin.firestore.FieldValue.serverTimestamp(),
                archiveMonth: prevMKey
            });
        });
        await batch.commit();
        console.log(`Archived ${snapshot.docs.length} records for month ${prevMKey}`);
    } else {
        console.log(`No records to archive for month ${prevMKey}`);
    }
    
    // Não precisa deletar, pois o novo mês terá nova chave mKey
    return null;
});