import { Router } from "express";
import { featureDetection } from "../services/featureDetection";
import { requireAuth } from "../middleware/auth";
import { prisma } from "../utils/db";
import { logger } from "../utils/logger";
import { config } from "../config";

const router = Router();

router.get("/features", requireAuth, async (req, res) => {
    try {
        const features = await featureDetection.getFeatures();
        res.json({
            ...features,
            audioAnalysis: config.features.audioAnalysis,
            discovery: config.features.discovery,
            autoPlaylists: config.features.autoPlaylists,
            federation: config.features.federation,
            loudnessTargetLufs: config.loudnessTargetLufs,
        });
    } catch (error: any) {
        logger.error("Feature detection error:", error);
        res.status(500).json({ error: "Failed to detect features" });
    }
});

/**
 * @openapi
 * /api/system/ui-settings:
 *   get:
 *     summary: Get public-facing UI settings
 *     tags: [System]
 *     security:
 *       - apiKeyAuth: []
 *     responses:
 *       200:
 *         description: UI settings (non-sensitive)
 *       401:
 *         description: Not authenticated
 */
router.get("/ui-settings", requireAuth, async (req, res) => {
    try {
        const settings = await prisma.systemSettings.findUnique({
            where: { id: "default" },
            select: { showVersion: true },
        });
        res.json({ showVersion: settings?.showVersion ?? false });
    } catch (error: any) {
        logger.error("UI settings error:", error);
        res.status(500).json({ error: "Failed to get UI settings" });
    }
});

export default router;
