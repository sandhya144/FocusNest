import express from 'express'
import cors from 'cors'
import { config } from './config/env.js'
import routes from './routes/index.js'
import { errorHandler } from './middleware/error.middleware.js'

const app = express()

// Middleware
app.use(cors({
  origin: [config.frontendUrl, 'http://localhost:3000'],
  credentials: true,
}))
app.use(express.json())

// Request logger in development
if (config.nodeEnv === 'development') {
  app.use((req, _res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`)
    next()
  })
}

// Routes
app.use('/api', routes)

// Central error handler
app.use(errorHandler)

// Server initialization
const PORT = config.port

if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => {
    console.log(`🚀 GroupLock Backend running on http://localhost:${PORT}`)
    console.log(`📡 API Endpoints available at http://localhost:${PORT}/api`)
  })
}

export default app

