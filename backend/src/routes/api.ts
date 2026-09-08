import { Router } from 'express';
import { register, login, getMe, switchMode, submitVerificationProfile } from '../controllers/authController';
import {
  createTask,
  getTasksFeed,
  getTaskById,
  acceptTask,
  createOffer,
  acceptOffer,
  startTask,
  submitProof,
  approveTask,
  disputeTask,
  rateTaskerByCustomer
} from '../controllers/taskController';
import { getWallet, requestWithdrawal, topUpWallet, toggleCardFreeze } from '../controllers/walletController';
import { getTaskMessages, sendMessage, getConversations, markMessagesAsRead } from '../controllers/chatController';
import { submitReview } from '../controllers/reviewController';
import {
  getAdminStats,
  getAllAdminUsers,
  verifyAdminUser,
  reviewAdminVerification,
  toggleAdminUserStatus,
  getAllAdminTasks,
  performAdminTaskAction,
  getAllAdminDisputes,
  resolveAdminDispute,
  broadcastAdminAnnouncement,
  rateAdminTask,
} from '../controllers/adminController';
import { authenticateJWT, optionalAuth } from '../middleware/auth';

const router = Router();

// Health Check
router.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'FINISH API Gateway', timestamp: new Date() });
});

// Authentication & Profile Verification
router.post('/auth/signup', register);
router.post('/auth/login', login);
router.get('/users/me', authenticateJWT, getMe);
router.patch('/users/mode', authenticateJWT, switchMode);
router.post('/users/verification', authenticateJWT, submitVerificationProfile);

// Tasks & Marketplace
router.post('/tasks', optionalAuth, createTask);
router.get('/tasks/feed', optionalAuth, getTasksFeed);
router.get('/tasks/:id', optionalAuth, getTaskById);
router.post('/tasks/:id/accept', optionalAuth, acceptTask);
router.post('/tasks/:id/offers', optionalAuth, createOffer);
router.post('/tasks/:id/offers/:offerId/accept', optionalAuth, acceptOffer);
router.post('/tasks/:id/start', optionalAuth, startTask);
router.post('/tasks/:id/proof', optionalAuth, submitProof);
router.post('/tasks/:id/approve', optionalAuth, approveTask);
router.post('/tasks/:id/rate', optionalAuth, rateTaskerByCustomer);
router.post('/tasks/:id/dispute', optionalAuth, disputeTask);

// Chat & Real-Time Messages
router.get('/conversations', optionalAuth, getConversations);
router.get('/tasks/:taskId/messages', optionalAuth, getTaskMessages);
router.post('/tasks/:taskId/messages', optionalAuth, sendMessage);
router.post('/tasks/:taskId/messages/read', optionalAuth, markMessagesAsRead);
router.patch('/tasks/:taskId/messages/read', optionalAuth, markMessagesAsRead);

// Financial Ledger & Wallet
router.get('/wallet', optionalAuth, getWallet);
router.post('/wallet/withdraw', optionalAuth, requestWithdrawal);
router.post('/wallet/topup', optionalAuth, topUpWallet);
router.post('/wallet/freeze', optionalAuth, toggleCardFreeze);

// Reviews & Reputation
router.post('/reviews', optionalAuth, submitReview);

// Admin Control Center
router.get('/admin/stats', getAdminStats);
router.get('/admin/users', getAllAdminUsers);
router.patch('/admin/users/:id/verify', verifyAdminUser);
router.post('/admin/users/:id/verification', reviewAdminVerification);
router.patch('/admin/users/:id/status', toggleAdminUserStatus);
router.get('/admin/tasks', getAllAdminTasks);
router.post('/admin/tasks/:id/action', performAdminTaskAction);
router.post('/admin/tasks/:id/rate', rateAdminTask);
router.get('/admin/disputes', getAllAdminDisputes);
router.post('/admin/disputes/:id/resolve', resolveAdminDispute);
router.post('/admin/broadcast', broadcastAdminAnnouncement);

export default router;
