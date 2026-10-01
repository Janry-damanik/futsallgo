const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret, defineString } = require('firebase-functions/params');

const midtransServerKey = defineSecret('MIDTRANS_SERVER_KEY');
const midtransApiBaseUrl = defineString('MIDTRANS_API_BASE_URL', {
  default: 'https://app.sandbox.midtrans.com/snap/v1',
});

exports.api = onRequest({
  secrets: [midtransServerKey],
  cors: true,
}, async (request, response) => {
  if (request.method !== 'POST') {
    response.status(404).json({error: 'Not found'});
    return;
  }

  if (request.path !== '/payments/snap-token') {
    response.status(404).json({error: 'Not found'});
    return;
  }

  const {orderId, grossAmount, fieldName, date, time} = request.body ?? {};
  if (!orderId || !Number.isInteger(grossAmount) || grossAmount <= 0) {
    response.status(400).json({error: 'Data pembayaran tidak valid.'});
    return;
  }

  const auth = Buffer.from(`${midtransServerKey.value()}:`).toString('base64');
  try {
    const midtransResponse = await fetch(`${midtransApiBaseUrl.value()}/transactions`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Authorization': `Basic ${auth}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        transaction_details: {order_id: orderId, gross_amount: grossAmount},
        item_details: [{
          id: orderId,
          price: grossAmount,
          quantity: 1,
          name: `${fieldName || 'Lapangan'} ${date || ''} ${time || ''}`.trim(),
        }],
      }),
    });

    const payload = await midtransResponse.json();
    if (!midtransResponse.ok || !payload.token) {
      response.status(midtransResponse.status || 502).json({
        error: payload.error_messages?.join(', ') || 'Midtrans gagal membuat token.',
      });
      return;
    }

    response.status(200).json({token: payload.token, redirect_url: payload.redirect_url});
  } catch (error) {
    console.error('Midtrans token request failed', error);
    response.status(502).json({error: 'Layanan pembayaran sedang tidak tersedia.'});
  }
});
