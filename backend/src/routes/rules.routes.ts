import { Router } from 'express'
import { getRules, updatePersonalRules } from '../controllers/rules.controller.js'
import { requireAuth } from '../middleware/auth.middleware.js'

const router = Router()

router.get('/', requireAuth, getRules)
router.post('/personal', requireAuth, updatePersonalRules)

export default router

