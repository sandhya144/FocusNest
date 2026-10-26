import { Router } from 'express'
import { reportActivity, getFocusState } from '../controllers/focus.controller.js'
import { optionalAuth } from '../middleware/auth.middleware.js'

const router = Router()

router.post('/activity', optionalAuth, reportActivity)
router.get('/room/:roomId', optionalAuth, getFocusState)

export default router

