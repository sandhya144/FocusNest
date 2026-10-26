import { Router } from 'express'
import healthRoutes from './health.routes.js'
import roomsRoutes from './rooms.routes.js'
import focusRoutes from './focus.routes.js'
import rulesRoutes from './rules.routes.js'

const router = Router()

router.use('/health', healthRoutes)
router.use('/rooms', roomsRoutes)
router.use('/focus', focusRoutes)
router.use('/rules', rulesRoutes)

export default router

