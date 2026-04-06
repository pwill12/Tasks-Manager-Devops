const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../server');

beforeAll(async () => {
  await mongoose.connect(process.env.MONGO_URI);
  server = app.listen(4000); // use a different port from dev
});

afterAll(async () => {
  await mongoose.connection.close(); // close DB
  await server.close();              // close Express server
});

describe('Health Check', () => {
  it('should return 200 on /healthz', async () => {
    const res = await request(app).get('/healthz');
    expect(res.statusCode).toBe(200);
  });

  it('should return 200 on /readyz', async () => {
    const res = await request(app).get('/readyz');
    expect(res.statusCode).toBe(200);
  });
});