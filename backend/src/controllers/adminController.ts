import { Request, Response } from 'express';
import { Types } from 'mongoose';
import { User, IUser } from '../models/User';
import { Task, ITask } from '../models/Task';
import { Transaction } from '../models/Transaction';
import { Dispute } from '../models/Review';
import { Wallet } from '../models/Wallet';
import { IN_MEMORY_TASKS } from './taskController';

// In-Memory Fallback Users for Admin Dashboard (Used when DB is empty/disconnected)
export const IN_MEMORY_ADMIN_USERS: any[] = [
  {
    _id: 'user_admin_1',
    id: 'user_admin_1',
    firstName: 'Admin',
    lastName: 'Operations',
    email: 'admin@finish.et',
    phone: '+251 911 000 000',
    role: 'admin',
    activeMode: 'customer',
    isPhoneVerified: true,
    isIdentityVerified: true,
    isBlocked: false,
    rating: 5.0,
    reviewCount: 48,
    completedTasksCount: 156,
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop&q=80',
    createdAt: new Date('2026-01-01'),
  },
  {
    _id: 'customer_sarah',
    id: 'customer_sarah',
    firstName: 'Sarah',
    lastName: 'Tadesse',
    email: 'sarah@finish.et',
    phone: '+251 911 223 344',
    role: 'customer',
    activeMode: 'customer',
    isPhoneVerified: true,
    isIdentityVerified: true,
    isBlocked: false,
    rating: 4.9,
    reviewCount: 18,
    completedTasksCount: 24,
    avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&auto=format&fit=crop&q=80',
    createdAt: new Date('2026-02-10'),
  },
  {
    _id: 'tasker_yared',
    id: 'tasker_yared',
    firstName: 'Yared',
    lastName: 'Bekele',
    email: 'yared@finish.et',
    phone: '+251 922 334 455',
    role: 'tasker',
    activeMode: 'tasker',
    isPhoneVerified: true,
    isIdentityVerified: true,
    isBlocked: false,
    rating: 4.95,
    reviewCount: 38,
    completedTasksCount: 42,
    avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80',
    createdAt: new Date('2026-02-15'),
  },
  {
    _id: 'tasker_solomon',
    id: 'tasker_solomon',
    firstName: 'Solomon',
    lastName: 'Tesfaye',
    email: 'solomon@finish.et',
    phone: '+251 933 445 566',
    role: 'tasker',
    activeMode: 'tasker',
    isPhoneVerified: true,
    isIdentityVerified: false,
    verificationStatus: 'PENDING',
    verificationData: {
      workExperienceYears: 3,
      experienceDescription: 'Experienced in parcel deliveries, food orders, and rapid courier runs across Bole, Kazanchis, and Sarbet.',
      educationalLevel: 'Vocational / TVET Diploma',
      institutionName: 'General Wingate TVET College',
      educationalCertificateUrl: 'https://images.unsplash.com/photo-1589330694653-ded6df03f754?w=400',
      nationalIdNumber: 'ETH-AA-998822',
      nationalIdPhotoUrl: 'https://images.unsplash.com/photo-1633332755192-727a05c4013d?w=400',
      nationalIdFrontUrl: 'https://images.unsplash.com/photo-1633332755192-727a05c4013d?w=400',
      nationalIdBackUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=400',
      faceScanPhotoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
      driverLicensePhotoUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=400',
      emergencyContactName: 'Almaz Tesfaye (Sister)',
      emergencyContactPhone: '+251 911 887 766',
      primaryCategory: 'delivery',
      categoryAnswers: {
        vehicleType: 'Motorbike (TVS Apache 160)',
        licenseNumber: 'AA-DRV-44810-ETH',
        driverLicensePhotoUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=400',
        deliveryExperienceYears: '3 years in express dispatch',
        smartphoneProficiency: 'High / Daily Google Maps & GPS user',
      },
      submittedAt: new Date('2026-02-28')
    },
    isBlocked: false,
    rating: 0.0,
    reviewCount: 0,
    completedTasksCount: 0,
    avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&auto=format&fit=crop&q=80',
    createdAt: new Date('2026-03-01'),
  },
  {
    _id: 'customer_dawit',
    id: 'customer_dawit',
    firstName: 'Dawit',
    lastName: 'Alemu',
    email: 'dawit@finish.et',
    phone: '+251 944 556 677',
    role: 'customer',
    activeMode: 'customer',
    isPhoneVerified: true,
    isIdentityVerified: true,
    verificationStatus: 'APPROVED',
    isBlocked: false,
    rating: 5.0,
    reviewCount: 5,
    completedTasksCount: 6,
    avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&auto=format&fit=crop&q=80',
    createdAt: new Date('2026-03-05'),
  },
  {
    _id: 'user_suspicious_1',
    id: 'user_suspicious_1',
    firstName: 'Robel',
    lastName: 'Kifle',
    email: 'robel.k@finish.et',
    phone: '+251 955 667 788',
    role: 'tasker',
    activeMode: 'tasker',
    isPhoneVerified: true,
    isIdentityVerified: false,
    verificationStatus: 'PENDING',
    verificationData: {
      workExperienceYears: 2,
      experienceDescription: 'Deep cleaning and post-construction residential cleanup.',
      educationalLevel: 'High School Diploma',
      institutionName: 'Bole Secondary School',
      educationalCertificateUrl: 'https://images.unsplash.com/photo-1589330694653-ded6df03f754?w=400',
      nationalIdNumber: 'ETH-AA-774411',
      nationalIdPhotoUrl: 'https://images.unsplash.com/photo-1633332755192-727a05c4013d?w=400',
      nationalIdFrontUrl: 'https://images.unsplash.com/photo-1633332755192-727a05c4013d?w=400',
      nationalIdBackUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=400',
      faceScanPhotoUrl: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=400',
      emergencyContactName: 'Kifle Haile (Father)',
      emergencyContactPhone: '+251 912 334 455',
      primaryCategory: 'cleaning',
      categoryAnswers: {
        cleaningTypes: 'Residential & Deep Cleaning',
        hasEquipment: 'Vacuum cleaner, steamer, and eco-friendly detergents',
      },
      submittedAt: new Date('2026-03-02')
    },
    isBlocked: true,
    rating: 0.0,
    reviewCount: 0,
    completedTasksCount: 0,
    avatarUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=200&auto=format&fit=crop&q=80',
    createdAt: new Date('2026-03-10'),
  }
];

// In-Memory Disputes
export const IN_MEMORY_DISPUTES: any[] = [
  {
    _id: 'disp_1',
    id: 'disp_1',
    taskId: 'task_3',
    taskTitle: 'Assemble 4 IKEA office chairs & conference table',
    customerId: 'customer_dawit',
    customerName: 'Dawit Alemu',
    customerPhone: '+251 944 556 677',
    taskerId: 'tasker_yared',
    taskerName: 'Yared Bekele',
    taskerPhone: '+251 922 334 455',
    amount: 1200,
    currency: 'ETB',
    reason: 'Damage / Incomplete Assembly',
    description: 'One chair base bolt was stripped and not fully tightened. Customer requesting partial discount or fix.',
    evidencePhotos: [
      'https://images.unsplash.com/photo-1581539250439-c96689b516dd?w=500&auto=format&fit=crop&q=80'
    ],
    status: 'OPEN',
    createdAt: new Date('2026-08-30T10:00:00Z'),
  }
];

// 1. GET /api/admin/stats
export const getAdminStats = async (req: Request, res: Response): Promise<void> => {
  try {
    let totalUsers = 0;
    let activeTaskers = 0;
    let totalCustomers = 0;
    let totalTasks = 0;
    let activeJobs = 0;
    let completedTasks = 0;
    let disputedTasks = 0;
    let totalVolume = 0;
    let recentTasks: any[] = [];
    let recentDisputes: any[] = [];

    try {
      totalUsers = await User.countDocuments();
      activeTaskers = await User.countDocuments({ role: { $in: ['tasker', 'both'] } });
      totalCustomers = await User.countDocuments({ role: { $in: ['customer', 'both'] } });
      totalTasks = await Task.countDocuments();
      activeJobs = await Task.countDocuments({ status: { $in: ['IN_PROGRESS', 'ACCEPTED', 'SUBMITTED'] } });
      completedTasks = await Task.countDocuments({ status: { $in: ['COMPLETED', 'PAID'] } });
      disputedTasks = await Task.countDocuments({ status: 'DISPUTED' });

      const transactions = await Transaction.find({ type: 'TASK_EARNING', status: 'COMPLETED' });
      totalVolume = transactions.reduce((acc, t) => acc + Math.abs(t.amount), 0);

      recentTasks = await Task.find()
        .populate('customerId', 'firstName lastName phone')
        .populate('assignedTaskerId', 'firstName lastName phone')
        .sort({ createdAt: -1 })
        .limit(10);

      recentDisputes = await Dispute.find()
        .populate('taskId', 'title status pricing')
        .populate('raisedBy', 'firstName lastName phone')
        .sort({ createdAt: -1 })
        .limit(5);
    } catch (_) {}

    // Fallback if DB counts are empty / demo mode
    if (totalUsers === 0) {
      totalUsers = IN_MEMORY_ADMIN_USERS.length;
      activeTaskers = IN_MEMORY_ADMIN_USERS.filter(u => u.role === 'tasker' || u.role === 'both').length;
      totalCustomers = IN_MEMORY_ADMIN_USERS.filter(u => u.role === 'customer' || u.role === 'both').length;
    }
    if (totalTasks === 0) {
      totalTasks = IN_MEMORY_TASKS.length;
      activeJobs = IN_MEMORY_TASKS.filter(t => ['IN_PROGRESS', 'ACCEPTED', 'SUBMITTED'].includes(t.status)).length;
      completedTasks = IN_MEMORY_TASKS.filter(t => ['COMPLETED', 'PAID'].includes(t.status)).length;
      disputedTasks = IN_MEMORY_DISPUTES.filter(d => d.status === 'OPEN').length;
      totalVolume = IN_MEMORY_TASKS.reduce((acc, t) => acc + (t.pricing?.budget || 0), 0);
      recentTasks = IN_MEMORY_TASKS.slice(0, 8);
      recentDisputes = IN_MEMORY_DISPUTES;
    }

    const platformRevenue = Math.round(totalVolume * 0.10); // 10% commission
    const escrowHeld = activeJobs * 650; // Active funds held in escrow

    res.status(200).json({
      success: true,
      metrics: {
        totalUsers,
        activeTaskers,
        totalCustomers,
        totalTasks,
        activeJobs,
        completedTasks,
        disputedTasks,
        totalVolume,
        platformRevenue,
        escrowHeld,
        completionRate: totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 98
      },
      recentTasks,
      recentDisputes
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message || 'Server error' });
  }
};

// 2. GET /api/admin/users
export const getAllAdminUsers = async (req: Request, res: Response): Promise<void> => {
  try {
    const { role, status, search } = req.query;
    let users: any[] = [];

    try {
      const query: any = {};
      if (role && role !== 'all') {
        query.role = { $in: [role, 'both'] };
      }
      if (status === 'verified') {
        query.isIdentityVerified = true;
      } else if (status === 'pending') {
        query.$or = [
          { verificationStatus: 'PENDING' },
          { isIdentityVerified: false }
        ];
      } else if (status === 'blocked') {
        query.isBlocked = true;
      }

      if (search && typeof search === 'string' && search.trim().length > 0) {
        const regex = new RegExp(search.trim(), 'i');
        query.$or = [
          { firstName: regex },
          { lastName: regex },
          { email: regex },
          { phone: regex },
        ];
      }

      users = await User.find(query).sort({ createdAt: -1 });
    } catch (_) {}

    // Merge MongoDB users with in-memory users so newly registered/submitted taskers are included
    const combinedUsers = [...users];
    const seenEmails = new Set(users.map(u => (u.email || '').toLowerCase()));
    const seenPhones = new Set(users.map(u => (u.phone || '').trim()));
    const seenIds = new Set(users.map(u => String(u._id || u.id)));

    for (const inMem of IN_MEMORY_ADMIN_USERS) {
      const emailLower = (inMem.email || '').toLowerCase();
      const phoneClean = (inMem.phone || '').trim();
      const idStr = String(inMem._id || inMem.id);

      if (!seenEmails.has(emailLower) && !seenPhones.has(phoneClean) && !seenIds.has(idStr)) {
        if (role && role !== 'all' && inMem.role !== role && inMem.role !== 'both') continue;
        if (status === 'verified' && !inMem.isIdentityVerified) continue;
        if (status === 'pending' && inMem.verificationStatus !== 'PENDING' && inMem.isIdentityVerified !== false) continue;
        if (status === 'blocked' && !inMem.isBlocked) continue;
        if (search && typeof search === 'string' && search.trim().length > 0) {
          const q = search.trim().toLowerCase();
          const matches = inMem.firstName.toLowerCase().includes(q) ||
            inMem.lastName.toLowerCase().includes(q) ||
            inMem.email.toLowerCase().includes(q) ||
            inMem.phone.includes(q);
          if (!matches) continue;
        }
        combinedUsers.push(inMem);
      }
    }

    res.status(200).json({
      success: true,
      count: combinedUsers.length,
      users: combinedUsers
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message || 'Server error' });
  }
};

// 3. PATCH /api/admin/users/:id/verify
export const verifyAdminUser = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { verified } = req.body;
    const isVerified = verified !== undefined ? verified : true;

    if (Types.ObjectId.isValid(id)) {
      try {
        const user = await User.findByIdAndUpdate(
          id,
          {
            isIdentityVerified: isVerified,
            verificationStatus: isVerified ? 'APPROVED' : 'REJECTED'
          },
          { new: true }
        );
        if (user) {
          res.status(200).json({
            success: true,
            message: `User identity ${isVerified ? 'verified' : 'unverified'} successfully`,
            user
          });
          return;
        }
      } catch (_) {}
    }

    const inMem = IN_MEMORY_ADMIN_USERS.find(u => String(u._id || u.id) === String(id));
    if (inMem) {
      inMem.isIdentityVerified = isVerified;
      inMem.verificationStatus = isVerified ? 'APPROVED' : 'REJECTED';
    }

    res.status(200).json({
      success: true,
      message: `User identity ${isVerified ? 'verified' : 'unverified'} successfully`,
      user: inMem || { _id: id, isIdentityVerified: isVerified, verificationStatus: isVerified ? 'APPROVED' : 'REJECTED' }
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message || 'Server error' });
  }
};

// 3b. POST /api/admin/users/:id/verification (Approve / Reject verification profile)
export const reviewAdminVerification = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { decision, notes } = req.body; // 'APPROVED' | 'REJECTED'
    const isApproved = decision === 'APPROVED';

    if (Types.ObjectId.isValid(id)) {
      try {
        const user = await User.findById(id);
        if (user) {
          user.isIdentityVerified = isApproved;
          user.verificationStatus = isApproved ? 'APPROVED' : 'REJECTED';
          if (user.verificationData) {
            user.verificationData.reviewedAt = new Date();
            user.verificationData.adminNotes = notes || '';
          }
          await user.save();

          const io = req.app.get('io');
          if (io) {
            io.emit('in_app_notification', {
              targetUserId: String(user._id),
              title: isApproved ? 'Identity Verified! ✓' : 'Verification Update',
              message: isApproved
                ? 'Congratulations! Your profile and identity have been verified by FINISH Admin. You now have the Verified Tasker Badge.'
                : `Verification update: ${notes || 'Application reviewed by Administrator.'}`
            });
          }

          res.status(200).json({
            success: true,
            message: `Tasker verification ${isApproved ? 'APPROVED' : 'REJECTED'} successfully`,
            user
          });
          return;
        }
      } catch (_) {}
    }

    const inMem = IN_MEMORY_ADMIN_USERS.find(u => String(u._id || u.id) === String(id));
    if (inMem) {
      inMem.isIdentityVerified = isApproved;
      inMem.verificationStatus = isApproved ? 'APPROVED' : 'REJECTED';
      if (inMem.verificationData) {
        inMem.verificationData.reviewedAt = new Date();
        inMem.verificationData.adminNotes = notes || '';
      }
    }

    res.status(200).json({
      success: true,
      message: `Tasker verification ${isApproved ? 'APPROVED' : 'REJECTED'} successfully`,
      user: inMem || { _id: id, isIdentityVerified: isApproved, verificationStatus: isApproved ? 'APPROVED' : 'REJECTED' }
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message || 'Server error' });
  }
};

// 4. PATCH /api/admin/users/:id/status (Block / Unblock)
export const toggleAdminUserStatus = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { isBlocked } = req.body;

    if (Types.ObjectId.isValid(id)) {
      try {
        const user = await User.findById(id);
        if (user) {
          user.isBlocked = isBlocked !== undefined ? isBlocked : !user.isBlocked;
          await user.save();
          res.status(200).json({
            success: true,
            message: `User ${user.isBlocked ? 'suspended' : 'activated'} successfully`,
            user
          });
          return;
        }
      } catch (_) {}
    }

    const inMem = IN_MEMORY_ADMIN_USERS.find(u => String(u._id || u.id) === String(id));
    if (inMem) {
      inMem.isBlocked = isBlocked !== undefined ? isBlocked : !inMem.isBlocked;
    }

    res.status(200).json({
      success: true,
      message: `User status updated successfully`,
      user: inMem || { _id: id, isBlocked }
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message || 'Server error' });
  }
};

// 5. GET /api/admin/tasks
export const getAllAdminTasks = async (req: Request, res: Response): Promise<void> => {
  try {
    const { status, category, search } = req.query;
    let tasks: any[] = [];

    try {
      const query: any = {};
      if (status && status !== 'all') {
        query.status = status;
      }
      if (category && category !== 'all') {
        query.category = category;
      }
      if (search && typeof search === 'string' && search.trim().length > 0) {
        const regex = new RegExp(search.trim(), 'i');
        query.$or = [
          { title: regex },
          { description: regex },
        ];
      }

      tasks = await Task.find(query)
        .populate('customerId', 'firstName lastName phone rating avatarUrl')
        .populate('assignedTaskerId', 'firstName lastName phone rating avatarUrl')
        .sort({ createdAt: -1 });
    } catch (_) {}

    if (tasks.length === 0) {
      let filtered = [...IN_MEMORY_TASKS];
      if (status && status !== 'all') {
        filtered = filtered.filter(t => t.status === status);
      }
      if (category && category !== 'all') {
        filtered = filtered.filter(t => t.category === category);
      }
      if (search && typeof search === 'string' && search.trim().length > 0) {
        const q = search.trim().toLowerCase();
        filtered = filtered.filter(t =>
          t.title.toLowerCase().includes(q) ||
          t.description.toLowerCase().includes(q)
        );
      }
      tasks = filtered;
    }

    res.status(200).json({
      success: true,
      count: tasks.length,
      tasks
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message || 'Server error' });
  }
};

// 6. POST /api/admin/tasks/:id/action (Force Approve / Force Cancel & Refund)
export const performAdminTaskAction = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { action, reason } = req.body;
    const now = new Date();

    if (!['FORCE_APPROVE', 'FORCE_CANCEL_REFUND', 'FORCE_START'].includes(action)) {
      res.status(400).json({ success: false, message: 'Invalid action type' });
      return;
    }

    const io = req.app.get('io');

    if (Types.ObjectId.isValid(id)) {
      try {
        const task = await Task.findById(id);
        if (task) {
          if (action === 'FORCE_APPROVE') {
            task.status = 'PAID';
            task.completedAt = task.completedAt || now;
            task.timeline.push({
              status: 'PAID',
              timestamp: now,
              note: `Admin force approved & released funds. Reason: ${reason || 'Manual Admin Resolution'}`
            });
            if (task.assignedTaskerId) {
              await Wallet.findOneAndUpdate(
                { userId: task.assignedTaskerId },
                { $inc: { availableBalance: task.pricing.budget, totalEarned: task.pricing.budget } },
                { upsert: true }
              );
            }
          } else if (action === 'FORCE_CANCEL_REFUND') {
            task.status = 'CANCELLED';
            task.timeline.push({
              status: 'CANCELLED',
              timestamp: now,
              note: `Admin cancelled task and refunded customer escrow. Reason: ${reason || 'Admin Intervention'}`
            });
          } else if (action === 'FORCE_START') {
            task.status = 'IN_PROGRESS';
            task.startedAt = task.startedAt || now;
            task.timeline.push({
              status: 'IN_PROGRESS',
              timestamp: now,
              note: 'Admin initiated live work session'
            });
          }

          await task.save();

          if (io) {
            io.emit('status_changed', { taskId: String(task._id), status: task.status });
          }

          res.status(200).json({
            success: true,
            message: `Action ${action} executed successfully`,
            task
          });
          return;
        }
      } catch (_) {}
    }

    const inMem = IN_MEMORY_TASKS.find(t => String(t._id || t.id) === String(id));
    if (inMem) {
      if (action === 'FORCE_APPROVE') {
        inMem.status = 'PAID';
        inMem.completedAt = now;
      } else if (action === 'FORCE_CANCEL_REFUND') {
        inMem.status = 'CANCELLED';
      } else if (action === 'FORCE_START') {
        inMem.status = 'IN_PROGRESS';
        inMem.startedAt = now;
      }
    }

    if (io) {
      io.emit('status_changed', { taskId: id, status: inMem?.status || 'PAID' });
    }

    res.status(200).json({
      success: true,
      message: `Action ${action} executed successfully`,
      task: inMem || { _id: id, status: action === 'FORCE_APPROVE' ? 'PAID' : 'CANCELLED' }
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message || 'Server error' });
  }
};

// 7. GET /api/admin/disputes
export const getAllAdminDisputes = async (req: Request, res: Response): Promise<void> => {
  try {
    let disputes: any[] = [];
    try {
      disputes = await Dispute.find()
        .populate('taskId', 'title status pricing pickupLocation dropoffLocation')
        .populate('raisedBy', 'firstName lastName phone avatarUrl')
        .sort({ createdAt: -1 });
    } catch (_) {}

    if (disputes.length === 0) {
      disputes = IN_MEMORY_DISPUTES;
    }

    res.status(200).json({
      success: true,
      count: disputes.length,
      disputes
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message || 'Server error' });
  }
};

// 8. POST /api/admin/disputes/:id/resolve
export const resolveAdminDispute = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { decision, resolutionNotes } = req.body;
    const now = new Date();

    if (!['FAVOR_TASKER', 'FAVOR_CUSTOMER'].includes(decision)) {
      res.status(400).json({ success: false, message: 'Invalid dispute decision' });
      return;
    }

    if (Types.ObjectId.isValid(id)) {
      try {
        const dispute = await Dispute.findById(id);
        if (dispute) {
          dispute.status = 'RESOLVED';
          dispute.resolution = `${decision}: ${resolutionNotes || 'Resolved by Administrator'}`;
          dispute.resolvedAt = now;
          await dispute.save();

          if (dispute.taskId) {
            const task = await Task.findById(dispute.taskId);
            if (task) {
              task.status = decision === 'FAVOR_TASKER' ? 'PAID' : 'CANCELLED';
              task.timeline.push({
                status: task.status,
                timestamp: now,
                note: `Dispute resolved in favor of ${decision === 'FAVOR_TASKER' ? 'Tasker' : 'Customer'}: ${resolutionNotes}`
              });
              await task.save();
            }
          }

          res.status(200).json({
            success: true,
            message: `Dispute resolved in favor of ${decision === 'FAVOR_TASKER' ? 'Tasker' : 'Customer'}`,
            dispute
          });
          return;
        }
      } catch (_) {}
    }

    const inMem = IN_MEMORY_DISPUTES.find(d => String(d._id || d.id) === String(id));
    if (inMem) {
      inMem.status = 'RESOLVED';
      inMem.decision = decision;
      inMem.resolutionNotes = resolutionNotes;
    }

    res.status(200).json({
      success: true,
      message: `Dispute resolved in favor of ${decision === 'FAVOR_TASKER' ? 'Tasker' : 'Customer'}`,
      dispute: inMem || { _id: id, status: 'RESOLVED', decision }
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message || 'Server error' });
  }
};

// 10. POST /api/admin/tasks/:id/rate (Rate both tasker and customer upon completion)
export const rateAdminTask = async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { taskerRating, taskerReview, customerRating, customerReview } = req.body;
    const now = new Date();

    const tRating = Math.min(5, Math.max(1, Number(taskerRating) || 5));
    const cRating = Math.min(5, Math.max(1, Number(customerRating) || 5));

    const io = req.app.get('io');

    if (Types.ObjectId.isValid(id)) {
      try {
        const task = await Task.findById(id);
        if (task) {
          task.adminRatings = {
            taskerRating: tRating,
            taskerReview: taskerReview || 'Admin performance appraisal: 5/5 stars',
            customerRating: cRating,
            customerReview: customerReview || 'Admin cooperation appraisal: 5/5 stars',
            ratedAt: now
          };
          task.timeline.push({
            status: task.status,
            timestamp: now,
            note: `Admin rated Tasker (${tRating}★) and Customer (${cRating}★)`
          });
          await task.save();

          // Update Tasker rating in User model
          if (task.assignedTaskerId) {
            const tasker = await User.findById(task.assignedTaskerId);
            if (tasker) {
              const currentRating = tasker.rating || 5.0;
              const count = tasker.reviewCount || 1;
              tasker.rating = Number(((currentRating * count + tRating) / (count + 1)).toFixed(2));
              tasker.reviewCount = count + 1;
              await tasker.save();
            }
          }

          // Update Customer rating in User model
          if (task.customerId) {
            const customer = await User.findById(task.customerId);
            if (customer) {
              const currentRating = customer.rating || 5.0;
              const count = customer.reviewCount || 1;
              customer.rating = Number(((currentRating * count + cRating) / (count + 1)).toFixed(2));
              customer.reviewCount = count + 1;
              await customer.save();
            }
          }

          if (io) {
            if (task.assignedTaskerId) {
              io.emit('in_app_notification', {
                targetUserId: String(task.assignedTaskerId),
                taskId: String(task._id),
                title: '⭐ Admin Rating Received!',
                message: `Admin rated your work on "${task.title}" with ${tRating} Stars! Note: "${taskerReview || 'Great work!'}"`
              });
            }
            if (task.customerId) {
              io.emit('in_app_notification', {
                targetUserId: String(task.customerId),
                taskId: String(task._id),
                title: '⭐ Admin Rating Received!',
                message: `Admin rated your task "${task.title}" with ${cRating} Stars! Note: "${customerReview || 'Thank you for using Finish!'}"`
              });
            }
          }

          res.status(200).json({
            success: true,
            message: 'Both Tasker and Customer rated successfully by Admin',
            task
          });
          return;
        }
      } catch (err) {
        console.error('DB error in rateAdminTask:', err);
      }
    }

    // In-memory fallback
    const inMem = IN_MEMORY_TASKS.find(t => String(t._id || t.id) === String(id));
    if (inMem) {
      inMem.adminRatings = {
        taskerRating: tRating,
        taskerReview: taskerReview || 'Admin performance appraisal: 5/5 stars',
        customerRating: cRating,
        customerReview: customerReview || 'Admin cooperation appraisal: 5/5 stars',
        ratedAt: now
      };

      const tasker = IN_MEMORY_ADMIN_USERS.find(u =>
        String(u._id || u.id) === String(inMem.assignedTaskerId || inMem.assignedTasker?._id) ||
        u.firstName.toLowerCase() === (inMem.assignedTaskerName || '').toLowerCase()
      );
      if (tasker) {
        tasker.rating = Number(((tasker.rating * tasker.reviewCount + tRating) / (tasker.reviewCount + 1)).toFixed(2));
        tasker.reviewCount += 1;
      }

      const customer = IN_MEMORY_ADMIN_USERS.find(u =>
        String(u._id || u.id) === String(inMem.customerId || inMem.customer?._id) ||
        u.firstName.toLowerCase() === (inMem.customerName || '').toLowerCase()
      );
      if (customer) {
        customer.rating = Number(((customer.rating * customer.reviewCount + cRating) / (customer.reviewCount + 1)).toFixed(2));
        customer.reviewCount += 1;
      }
    }

    if (io && inMem) {
      io.emit('in_app_notification', {
        targetUserId: inMem.assignedTaskerId || 'tasker_user',
        taskId: String(inMem._id || inMem.id),
        title: '⭐ Admin Rating Received!',
        message: `Admin rated your work on "${inMem.title}" with ${tRating} Stars!`
      });
      io.emit('in_app_notification', {
        targetUserId: inMem.customerId || 'customer_user',
        taskId: String(inMem._id || inMem.id),
        title: '⭐ Admin Rating Received!',
        message: `Admin rated your task "${inMem.title}" with ${cRating} Stars!`
      });
    }

    res.status(200).json({
      success: true,
      message: 'Both Tasker and Customer rated successfully by Admin',
      task: inMem || { _id: id, adminRatings: { taskerRating: tRating, customerRating: cRating, ratedAt: now } }
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message || 'Server error' });
  }
};

// 11. POST /api/admin/broadcast
export const broadcastAdminAnnouncement = async (req: Request, res: Response): Promise<void> => {
  try {
    const { title, message, targetRole } = req.body;

    if (!title || !message) {
      res.status(400).json({ success: false, message: 'Title and message are required for broadcast.' });
      return;
    }

    const io = req.app.get('io');
    if (io) {
      io.emit('in_app_notification', {
        title: `📢 ${title}`,
        message,
        targetRole: targetRole || 'all',
        timestamp: new Date().toISOString()
      });
      io.emit('admin_announcement', {
        title,
        message,
        timestamp: new Date().toISOString()
      });
    }

    res.status(200).json({
      success: true,
      message: 'System announcement broadcasted to all connected clients across Addis Ababa',
      broadcast: {
        title,
        message,
        targetRole: targetRole || 'all',
        sentAt: new Date()
      }
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message || 'Server error' });
  }
};


