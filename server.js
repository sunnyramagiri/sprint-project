const express = require('express');

const app = express();
const PORT = 3000;

app.get('/', (req, res) => {
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>DevOps CI/CD Project</title>
            <style>
                body {
                    font-family: Arial, sans-serif;
                    background: linear-gradient(135deg, #667eea, #764ba2);
                    color: white;
                    text-align: center;
                    padding-top: 100px;
                }
                .card {
                    background: white;
                    color: #333;
                    padding: 40px;
                    margin: auto;
                    width: 70%;
                    max-width: 600px;
                    border-radius: 15px;
                    box-shadow: 0 8px 25px rgba(0,0,0,0.2);
                }
                h1 {
                    color: #4f46e5;
                }
                .success {
                    color: green;
                    font-weight: bold;
                }
            </style>
        </head>
        <body>
            <div class="card">
                <h1>🚀 CI/CD Pipeline Successful!</h1>
                <p class="success">Application is running successfully.</p>
                <p>GitHub → Jenkins → Maven → Docker → Docker Hub → EC2</p>
                <p>Deployed using Jenkins CI pipeline.</p>
            </div>
        </body>
        </html>
    `);
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Application running on port ${PORT}`);
});
