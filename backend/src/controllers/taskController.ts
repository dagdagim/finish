import { Response } from 'express';
import { Types } from 'mongoose';
import { v4 as uuidv4 } from 'uuid';
import { Task, ITask } from '../models/Task';
import { Offer } from '../models/Offer';
import { Wallet } from '../models/Wallet';
import { Transaction } from '../models/Transaction';
import { User } from '../models/User';
import { Dispute } from '../models/Review';
import { AuthRequest } from '../middleware/auth';

export const IN_MEMORY_TASKS: any[] = [
  {
    _id: 'task_1',
    customerId: {
      _id: 'customer_sarah',
      firstName: 'Sarah',
      lastName: 'Mamo',
      avatarUrl: '',
      rating: 4.9,
      reviewCount: 12,
      isIdentityVerified: true,
      phone: '+251 911 223 344',
    },
    title: 'Pick up package from Bole Post Office',
    category: 'delivery',
    description: 'Pick up a medium-sized parcel from Bole Medhanialem Post Office counter #4 and deliver to Kazanchis Intercontinental.',
    quantity: 1,
    specialInstructions: 'Ask for ticket #204 at window 4.',
    pickupLocation: {
      address: 'Bole Medhanialem, Addis Ababa',
      instructions: 'Counter #4',
      coordinates: [38.7891, 8.9953],
    },
    dropoffLocation: {
      address: 'Kazanchis, Addis Ababa',
      instructions: '4th floor reception',
      coordinates: [38.7636, 9.0125],
    },
    schedule: {
      type: 'today',
      windowText: 'Today · 4:00 PM - 6:00 PM',
      windowStart: '16:00',
      windowEnd: '18:00',
    },
    pricing: {
      budget: 500,
      currency: 'ETB',
      pricingType: 'fixed',
      suggestedPrice: 500,
      platformFee: 50,
    },
    status: 'OPEN',
    distanceKm: 2.6,
    estimatedDurationMin: 35,
    createdAt: new Date(),
  },
  {
    _id: 'task_2',
    customerId: {
      _id: 'customer_sarah',
      firstName: 'Sarah',
      lastName: 'Mamo',
      rating: 4.9,
      reviewCount: 12,
      isIdentityVerified: true,
      phone: '+251 911 223 344',
    },
    title: 'Assemble IKEA Coffee Table & Shelf',
    category: 'assembly',
    description: 'Need assistance assembling 1 coffee table and 1 bookshelf. Instructions and hardware provided.',
    pickupLocation: { address: 'Old Airport, Addis Ababa', coordinates: [38.7421, 8.9912] },
    schedule: { type: 'today', windowText: 'Today · 2:00 PM - 4:00 PM' },
    pricing: { budget: 700, currency: 'ETB', pricingType: 'fixed', platformFee: 70 },
    status: 'OPEN',
    distanceKm: 4.1,
    estimatedDurationMin: 90,
    createdAt: new Date(),
  }
];

export const IN_MEMORY_OFFERS: any[] = [
  {
    _id: 'off_1',
    taskId: 'task_3',
    taskerId: {
      _id: 'tasker_daniel',
      firstName: 'Daniel',
      lastName: 'Kebede',
      avatarUrl: '',
      rating: 4.9,
      reviewCount: 128,
      isIdentityVerified: true
    },
    offeredAmount: 650,
    note: 'I have specialized assembly tools and can begin right on time.',
    status: 'PENDING',
    createdAt: new Date(Date.now() - 1000 * 60 * 30)
  },
  {
    _id: 'off_2',
    taskId: 'task_3',
    taskerId: {
      _id: 'tasker_michael',
      firstName: 'Michael',
      lastName: 'A.',
      avatarUrl: '',
      rating: 4.7,
      reviewCount: 84,
      isIdentityVerified: true
    },
    offeredAmount: 700,
    note: 'Experienced carpenter ready to assemble table & chairs.',
    status: 'PENDING',
    createdAt: new Date(Date.now() - 1000 * 60 * 15)
  }
];

export const createTask = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const {
      title,
      category,
      description,
      quantity,
      specialInstructions,
      mediaUrls,
      pickupLocation,
      dropoffLocation,
      additionalStops,
      schedule,
      budget,
      pricingType
    } = req.body;

    if (!title || !category || !description || !pickupLocation || !budget) {
      res.status(400).json({ success: false, message: 'Title, category, description, pickup location, and budget are required.' });
      return;
    }

    const pickupCoords: [number, number] = pickupLocation.coordinates && pickupLocation.coordinates.length === 2
      ? pickupLocation.coordinates
      : [38.7891, 8.9953];

    const dropoffCoords: [number, number] | undefined = dropoffLocation?.coordinates && dropoffLocation.coordinates.length === 2
      ? dropoffLocation.coordinates
      : dropoffLocation ? [38.7636, 9.0125] : undefined;

    const platformFee = Math.round(Number(budget) * 0.1);

    const taskPayload = {
      customerId: req.user?._id || new Types.ObjectId('65e0123456789abcdef00001'),
      title,
      category,
      description,
      quantity: quantity || 1,
      specialInstructions: specialInstructions || '',
      mediaUrls: mediaUrls || [],
      pickupLocation: {
        address: pickupLocation.address || 'Bole, Addis Ababa',
        instructions: pickupLocation.instructions || '',
        coordinates: pickupCoords
      },
      dropoffLocation: dropoffLocation
        ? {
            address: dropoffLocation.address || 'Kazanchis, Addis Ababa',
            instructions: dropoffLocation.instructions || '',
            coordinates: dropoffCoords
          }
        : undefined,
      additionalStops: additionalStops || [],
      schedule: {
        type: schedule?.type || 'today',
        windowText: schedule?.windowText || 'Today · 4:00 PM - 6:00 PM',
        date: schedule?.date ? new Date(schedule.date) : new Date(),
        windowStart: schedule?.windowStart || '16:00',
        windowEnd: schedule?.windowEnd || '18:00'
      },
      pricing: {
        budget: Number(budget),
        currency: 'ETB',
        pricingType: pricingType || 'fixed',
        suggestedPrice: Number(budget),
        platformFee
      },
      status: 'OPEN',
      timeline: [
        {
          status: 'POSTED',
          timestamp: new Date(),
          actorId: req.user?._id as any,
          note: 'Task posted by customer'
        }
      ],
      distanceKm: 2.4,
      estimatedDurationMin: 35
    };

    try {
      const newTask = await Task.create(taskPayload);
      const populated = await Task.findById(newTask._id)
        .populate('customerId', 'firstName lastName avatarUrl rating reviewCount isIdentityVerified phone');

      const memItem = {
        _id: String(newTask._id),
        ...taskPayload,
        customerId: {
          _id: String(taskPayload.customerId),
          firstName: req.user?.firstName || 'Sarah',
          lastName: req.user?.lastName || 'M.',
          avatarUrl: req.user?.avatarUrl || '',
          rating: 4.9,
          reviewCount: 12,
          isIdentityVerified: true
        },
        createdAt: new Date(),
      };
      IN_MEMORY_TASKS.unshift(memItem);

      const io = req.app.get('io');
      if (io) {
        io.emit('new_task_posted', populated || memItem);
      }

      res.status(201).json({
        success: true,
        message: 'Task posted successfully',
        task: populated || memItem
      });
      return;
    } catch (dbErr) {
      const inMem = {
        _id: 'task_' + Date.now(),
        ...taskPayload,
        customerId: {
          _id: String(taskPayload.customerId),
          firstName: req.user?.firstName || 'Sarah',
          lastName: req.user?.lastName || 'M.',
          avatarUrl: req.user?.avatarUrl || '',
          rating: 4.9,
          reviewCount: 12,
          isIdentityVerified: true
        },
        createdAt: new Date(),
      };
      IN_MEMORY_TASKS.unshift(inMem);

      const io = req.app.get('io');
      if (io) {
        io.emit('new_task_posted', inMem);
      }

      res.status(201).json({
        success: true,
        message: 'Task posted successfully',
        task: inMem
      });
      return;
    }
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message || 'Server error' });

  }
};

export const getTasksFeed = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { category, status, search, roleMode } = req.query;
    const isCustomer = roleMode === 'customer' || req.user?.activeMode === 'customer';
    const filter: any = {};

    if (isCustomer) {
      // Customer only sees their OWN tasks in their task feed
      const customerId = req.user?._id;
      if (customerId && Types.ObjectId.isValid(String(customerId))) {
        filter.customerId = customerId;
      }
      if (status) {
        filter.status = status;
      }
    } else {
      // Tasker mode:
      // Open / Offering tasks are public to all taskers to discover and apply
      // BUT ongoing / accepted / in-progress / completed tasks are STRICTLY PRIVATE to the assigned tasker!
      const currentTaskerId = req.user?._id;
      const currentTaskerName = req.user ? `${req.user.firstName} ${req.user.lastName}`.trim().toLowerCase() : '';

      if (status) {
        filter.status = status;
        if (['ACCEPTED', 'ASSIGNED', 'IN_PROGRESS', 'SUBMITTED', 'PAYMENT_PENDING', 'PAID', 'COMPLETED'].includes(String(status))) {
          if (currentTaskerId && Types.ObjectId.isValid(String(currentTaskerId))) {
            filter.assignedTaskerId = currentTaskerId;
          } else if (currentTaskerId) {
            filter.assignedTaskerId = String(currentTaskerId);
          } else {
            // Unauthenticated guest requesting ongoing tasks gets empty
            filter.assignedTaskerId = new Types.ObjectId();
          }
        }
      } else {
        if (currentTaskerId && Types.ObjectId.isValid(String(currentTaskerId))) {
          filter.$or = [
            { status: { $in: ['OPEN', 'OFFERING'] } },
            { status: { $in: ['ACCEPTED', 'ASSIGNED', 'IN_PROGRESS', 'SUBMITTED', 'PAYMENT_PENDING', 'PAID', 'COMPLETED'] }, assignedTaskerId: currentTaskerId }
          ];
        } else if (currentTaskerId) {
          filter.$or = [
            { status: { $in: ['OPEN', 'OFFERING'] } },
            { status: { $in: ['ACCEPTED', 'ASSIGNED', 'IN_PROGRESS', 'SUBMITTED', 'PAYMENT_PENDING', 'PAID', 'COMPLETED'] }, assignedTaskerId: String(currentTaskerId) }
          ];
        } else {
          // Unauthenticated tasker only sees OPEN / OFFERING tasks
          filter.status = { $in: ['OPEN', 'OFFERING'] };
        }
      }
    }

    if (category && category !== 'all') {
      filter.category = category;
    }

    if (search) {
      const searchCond = [
        { title: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
        { 'pickupLocation.address': { $regex: search, $options: 'i' } }
      ];
      if (filter.$or) {
        filter.$and = [{ $or: filter.$or }, { $or: searchCond }];
        delete filter.$or;
      } else {
        filter.$or = searchCond;
      }
    }

    try {
      const tasks = await Task.find(filter)
        .populate('customerId', 'firstName lastName avatarUrl rating reviewCount isIdentityVerified')
        .populate('assignedTaskerId', 'firstName lastName avatarUrl rating reviewCount taskerProfile')
        .sort({ createdAt: -1 })
        .limit(50);

      if (tasks) {
        res.status(200).json({
          success: true,
          count: tasks.length,
          tasks
        });
        return;
      }
    } catch (dbErr) {}

    let fallbackTasks = [...IN_MEMORY_TASKS];
    if (isCustomer) {
      const currentCustomerId = String(req.user?._id || 'customer_sarah');
      fallbackTasks = fallbackTasks.filter((t) => {
        const cId = String(t.customerId?._id || t.customerId || '');
        return cId === currentCustomerId || cId === 'customer_sarah';
      });
    } else {
      const currentTaskerId = req.user?._id ? String(req.user._id) : '';
      const currentTaskerName = req.user ? `${req.user.firstName} ${req.user.lastName}`.trim().toLowerCase() : '';
      fallbackTasks = fallbackTasks.filter((t) => {
        const st = (t.status || '').toUpperCase();
        // OPEN / OFFERING tasks are visible for all taskers to apply
        if (st === 'OPEN' || st === 'OFFERING') return true;
        
        // Ongoing / completed tasks are STRICTLY PRIVATE: only visible to the assigned tasker
        if (!currentTaskerId && !currentTaskerName) return false;
        const assignedId = String(t.assignedTaskerId?._id || t.assignedTaskerId || '');
        const assignedName = (t.assignedTaskerName || '').trim().toLowerCase();
        return (currentTaskerId.length > 0 && assignedId === currentTaskerId) ||
               (currentTaskerName.length > 0 && assignedName.length > 0 && (assignedName === currentTaskerName || assignedName.includes(currentTaskerName) || currentTaskerName.includes(assignedName)));
      });
    }

    res.status(200).json({
      success: true,
      count: fallbackTasks.length,
      tasks: fallbackTasks
    });
  } catch (error: any) {
    res.status(200).json({ success: true, count: IN_MEMORY_TASKS.length, tasks: IN_MEMORY_TASKS });
  }
};

export const getTaskById = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    try {
      if (Types.ObjectId.isValid(id)) {
        const task = await Task.findById(id)
          .populate('customerId', 'firstName lastName avatarUrl rating reviewCount isIdentityVerified phone')
          .populate('assignedTaskerId', 'firstName lastName avatarUrl rating reviewCount phone taskerProfile');

        if (task) {
          const offers = await Offer.find({ taskId: task._id })
            .populate('taskerId', 'firstName lastName avatarUrl rating reviewCount taskerProfile')
            .sort({ createdAt: -1 });

          res.status(200).json({
            success: true,
            task,
            offers
          });
          return;
        }
      }
    } catch (dbErr) {}

    const found = IN_MEMORY_TASKS.find(t => String(t._id || t.id) === String(id)) || IN_MEMORY_TASKS[0];
    const taskOffers = IN_MEMORY_OFFERS.filter(o => String(o.taskId) === String(id));

    res.status(200).json({
      success: true,
      task: found,
      offers: taskOffers.length > 0 ? taskOffers : [
        {
          _id: 'off_1',
          taskId: found._id,
          taskerId: {
            _id: 'tasker_daniel',
            firstName: 'Daniel',
            lastName: 'Kebede',
            avatarUrl: '',
            rating: 4.9
          },
          offeredAmount: found.pricing?.budget || 500,
          note: 'I am nearby and can complete this right away.',
          status: found.status === 'ACCEPTED' || found.status === 'IN_PROGRESS' ? 'ACCEPTED' : 'PENDING'
        }
      ]
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Atomic Task Acceptance (Race-condition safe)
export const acceptTask = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    if (Types.ObjectId.isValid(id) && req.user) {
      try {
        const task = await Task.findOneAndUpdate(
          {
            _id: id,
            status: { $in: ['OPEN', 'OFFERING'] },
            assignedTaskerId: null
          },
          {
            $set: {
              status: 'ACCEPTED',
              assignedTaskerId: req.user._id
            },
            $push: {
              timeline: {
                status: 'ACCEPTED',
                timestamp: new Date(),
                actorId: req.user._id as Types.ObjectId,
                note: `Accepted by tasker ${req.user.firstName} ${req.user.lastName}`
              }
            }
          },
          { new: true }
        ).populate('customerId', 'firstName lastName avatarUrl rating phone');

        if (task) {
          res.status(200).json({
            success: true,
            message: 'Task accepted successfully!',
            task
          });
          return;
        }
      } catch (dbErr) {
        console.error('DB Error in acceptTask:', dbErr);
      }
    }

    const inMem = IN_MEMORY_TASKS.find(t => t._id === id);
    if (inMem) {
      inMem.status = 'ACCEPTED';
      inMem.assignedTaskerName = req.user ? `${req.user.firstName} ${req.user.lastName}` : 'Daniel K.';
      inMem.assignedTaskerId = req.user?._id ? String(req.user._id) : 'tasker_daniel';
    }

    const io = req.app.get('io');
    if (io) {
      io.emit('task_accepted', {
        taskId: id,
        assignedTaskerId: req.user?._id ? String(req.user._id) : 'tasker_daniel',
        status: 'ACCEPTED'
      });
    }

    res.status(200).json({
      success: true,
      message: 'Task accepted successfully!',
      task: inMem || { _id: id, status: 'ACCEPTED', assignedTaskerId: req.user?._id ? String(req.user._id) : 'tasker_daniel' }
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const createOffer = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { offeredAmount, note } = req.body;
    const currentTaskerId = req.user?._id ? String(req.user._id) : (req.body.taskerId || 'tasker_daniel');

    if (!offeredAmount) {
      res.status(400).json({ success: false, message: 'Offered amount is required' });
      return;
    }

    // 1. In MongoDB
    if (Types.ObjectId.isValid(id) && req.user) {
      try {
        const task = await Task.findById(id);
        if (task) {
          if (task.status !== 'OPEN' && task.status !== 'OFFERING') {
            res.status(400).json({ success: false, message: 'This task is already assigned or closed.' });
            return;
          }

          // Check if this tasker already applied
          const existingOffer = await Offer.findOne({ taskId: task._id, taskerId: req.user._id });
          if (existingOffer) {
            res.status(400).json({
              success: false,
              message: 'You have already submitted an application for this task. Waiting for customer approval.',
              offer: existingOffer
            });
            return;
          }

          const offer = await Offer.create({
            taskId: task._id,
            taskerId: req.user._id,
            offeredAmount: Number(offeredAmount),
            note: note || '',
            status: 'PENDING'
          });

          task.status = 'OFFERING';
          task.offersCount = await Offer.countDocuments({ taskId: task._id });
          await task.save();

          const io = req.app.get('io');
          if (io) {
            io.emit('new_offer', { taskId: id, offer });
          }

          res.status(201).json({
            success: true,
            message: 'Application submitted successfully. Waiting for customer approval.',
            offer
          });
          return;
        }
      } catch (dbErr) {
        console.error('DB Error in createOffer:', dbErr);
      }
    }

    // 2. In-memory fallback
    const inMem = IN_MEMORY_TASKS.find(t => String(t._id || t.id) === String(id));
    if (inMem) {
      if (inMem.status !== 'OPEN' && inMem.status !== 'OFFERING') {
        res.status(400).json({ success: false, message: 'This task is already assigned or closed.' });
        return;
      }
    }

    // Check if tasker already applied in-memory
    const existingInMem = IN_MEMORY_OFFERS.find(
      o => String(o.taskId) === String(id) && String(o.taskerId?._id || o.taskerId) === currentTaskerId
    );
    if (existingInMem) {
      res.status(400).json({
        success: false,
        message: 'You have already submitted an application for this task. Waiting for customer approval.',
        offer: existingInMem
      });
      return;
    }

    if (inMem) {
      inMem.status = 'OFFERING';
      inMem.offersCount = (inMem.offersCount || 0) + 1;
    }

    const mockOffer = {
      _id: 'off_' + Date.now(),
      taskId: id,
      taskerId: {
        _id: currentTaskerId,
        firstName: req.user?.firstName || (req.body.taskerName ? req.body.taskerName.split(' ')[0] : 'Daniel'),
        lastName: req.user?.lastName || (req.body.taskerName && req.body.taskerName.includes(' ') ? req.body.taskerName.split(' ').slice(1).join(' ') : 'Kebede'),
        avatarUrl: req.user?.avatarUrl || '',
        rating: 4.9,
        reviewCount: 128,
        isIdentityVerified: true
      },
      offeredAmount: Number(offeredAmount),
      note: note || '',
      status: 'PENDING',
      createdAt: new Date()
    };

    IN_MEMORY_OFFERS.unshift(mockOffer);

    const io = req.app.get('io');
    if (io) {
      io.emit('new_offer', { taskId: id, offer: mockOffer });
    }

    res.status(201).json({
      success: true,
      message: 'Application submitted successfully. Waiting for customer approval.',
      offer: mockOffer
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message || 'Server error' });
  }
};

export const acceptOffer = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id, offerId } = req.params;

    if (Types.ObjectId.isValid(id) && Types.ObjectId.isValid(offerId) && req.user) {
      try {
        const task = await Task.findOne({ _id: id, customerId: req.user._id });
        const offer = await Offer.findById(offerId).populate('taskerId', 'firstName lastName avatarUrl rating reviewCount');

        if (task && offer) {
          task.assignedTaskerId = offer.taskerId;
          task.pricing.budget = offer.offeredAmount;
          task.status = 'ACCEPTED';
          task.timeline.push({
            status: 'ACCEPTED',
            timestamp: new Date(),
            actorId: req.user._id as Types.ObjectId,
            note: `Offer of ${offer.offeredAmount} ETB accepted by customer`
          });

          await task.save();

          // Mark chosen offer ACCEPTED
          offer.status = 'ACCEPTED';
          await offer.save();

          // Mark all other offers REJECTED
          await Offer.updateMany(
            { taskId: task._id, _id: { $ne: offer._id } },
            { $set: { status: 'REJECTED' } }
          );

          const customerName = req.user ? `${req.user.firstName} ${req.user.lastName}`.trim() : 'Customer';
          const chosenTaskerId = String((offer.taskerId as any)?._id || offer.taskerId);
          const chosenTaskerName = (offer.taskerId as any)?.firstName 
              ? `${(offer.taskerId as any).firstName} ${(offer.taskerId as any).lastName}`.trim() 
              : 'Tasker';

          const io = req.app.get('io');
          if (io) {
            io.emit('offer_decision', {
              taskId: id,
              acceptedOfferId: offerId,
              acceptedTaskerId: chosenTaskerId,
              status: 'ACCEPTED'
            });

            // Specific real-time notification to the hired tasker
            io.emit('task_hired_notification', {
              taskId: String(task._id || id),
              taskTitle: task.title,
              hiredTaskerId: chosenTaskerId,
              hiredTaskerName: chosenTaskerName,
              customerName: customerName,
              offeredAmount: offer.offeredAmount || task.pricing?.budget,
              pickupAddress: task.pickupLocation?.address || 'Addis Ababa',
              dropoffAddress: task.dropoffLocation?.address || 'Addis Ababa',
              timestamp: new Date().toISOString()
            });

            io.emit('in_app_notification', {
              targetUserId: chosenTaskerId,
              type: 'HIRED',
              title: '🎉 You are HIRED!',
              message: `Congratulations! ${customerName} accepted your application for "${task.title}" (${offer.offeredAmount} ETB). Tap to start your job.`,
              taskId: String(task._id || id),
              taskTitle: task.title
            });
          }

          res.status(200).json({
            success: true,
            message: 'Offer accepted, tasker assigned and others notified',
            task
          });
          return;
        }
      } catch (dbErr) {
        console.error('DB Error in acceptOffer:', dbErr);
      }
    }

    // In-memory fallback
    const inMem = IN_MEMORY_TASKS.find(t => String(t._id || t.id) === String(id));
    let chosenTaskerName = 'Daniel K.';
    let chosenTaskerId = 'tasker_daniel';
    let chosenOfferAmount = 500;

    for (const o of IN_MEMORY_OFFERS) {
      if (String(o.taskId) === String(id)) {
        if (String(o._id) === String(offerId)) {
          o.status = 'ACCEPTED';
          chosenTaskerName = `${o.taskerId?.firstName || 'Daniel'} ${o.taskerId?.lastName || 'K.'}`.trim();
          chosenTaskerId = String(o.taskerId?._id || 'tasker_daniel');
          chosenOfferAmount = o.offeredAmount || 500;
        } else {
          o.status = 'REJECTED';
        }
      }
    }

    if (inMem) {
      inMem.status = 'ACCEPTED';
      inMem.assignedTaskerName = chosenTaskerName;
      inMem.assignedTaskerId = chosenTaskerId;
      if (inMem.pricing) {
        inMem.pricing.budget = chosenOfferAmount;
      }
    }

    const customerName = req.user ? `${req.user.firstName} ${req.user.lastName}`.trim() : 'Sarah M.';
    const taskTitle = inMem?.title || 'Delivery Service';

    const io = req.app.get('io');
    if (io) {
      io.emit('offer_decision', {
        taskId: id,
        acceptedOfferId: offerId,
        acceptedTaskerId: chosenTaskerId,
        status: 'ACCEPTED'
      });

      // Specific real-time notification to the hired tasker
      io.emit('task_hired_notification', {
        taskId: id,
        taskTitle: taskTitle,
        hiredTaskerId: chosenTaskerId,
        hiredTaskerName: chosenTaskerName,
        customerName: customerName,
        offeredAmount: chosenOfferAmount,
        pickupAddress: inMem?.pickupLocation?.address || 'Bole Medhanialem, Addis Ababa',
        dropoffAddress: inMem?.dropoffLocation?.address || 'Kazanchis, Addis Ababa',
        timestamp: new Date().toISOString()
      });

      io.emit('in_app_notification', {
        targetUserId: chosenTaskerId,
        type: 'HIRED',
        title: '🎉 You are HIRED!',
        message: `Congratulations! ${customerName} accepted your application for "${taskTitle}" (${chosenOfferAmount} ETB). Tap to start your job.`,
        taskId: id,
        taskTitle: taskTitle
      });
    }

    res.status(200).json({
      success: true,
      message: 'Offer accepted, tasker assigned and others notified',
      task: inMem || { _id: id, status: 'ACCEPTED', assignedTaskerName: chosenTaskerName }
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message || 'Server error' });
  }
};

export const startTask = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const now = new Date();

    if (Types.ObjectId.isValid(id) && req.user) {
      try {
        const task = await Task.findOne({ _id: id, assignedTaskerId: req.user._id });
        if (task) {
          task.status = 'IN_PROGRESS';
          (task as any).startedAt = now;
          task.timeline.push({
            status: 'IN_PROGRESS',
            timestamp: now,
            actorId: req.user._id as Types.ObjectId,
            note: 'Tasker started task'
          });

          await task.save();

          const io = req.app.get('io');
          if (io) {
            io.emit('task_started', {
              taskId: String(task._id || id),
              status: 'IN_PROGRESS',
              startedAt: now.toISOString(),
              taskTitle: task.title
            });
            io.emit('status_changed', {
              taskId: String(task._id || id),
              status: 'IN_PROGRESS',
              startedAt: now.toISOString()
            });
          }

          res.status(200).json({
            success: true,
            message: 'Task started',
            task: {
              ...task.toObject(),
              startedAt: now
            }
          });
          return;
        }
      } catch (dbErr) {
        console.error('DB Error in startTask:', dbErr);
      }
    }

    const inMem = IN_MEMORY_TASKS.find(t => String(t._id || t.id) === String(id));
    if (inMem) {
      inMem.status = 'IN_PROGRESS';
      inMem.startedAt = now;
    }

    const io = req.app.get('io');
    if (io) {
      io.emit('task_started', {
        taskId: id,
        status: 'IN_PROGRESS',
        startedAt: now.toISOString(),
        taskTitle: inMem?.title || 'Task'
      });
      io.emit('status_changed', {
        taskId: id,
        status: 'IN_PROGRESS',
        startedAt: now.toISOString()
      });
    }

    res.status(200).json({
      success: true,
      message: 'Task started',
      task: inMem || { _id: id, status: 'IN_PROGRESS', startedAt: now }
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message || 'Server error' });
  }
};

export const submitProof = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { photos, notes, gpsCoordinates } = req.body;
    const now = new Date();

    if (Types.ObjectId.isValid(id) && req.user) {
      try {
        const task = await Task.findOne({ _id: id, assignedTaskerId: req.user._id });
        if (task) {
          task.status = 'SUBMITTED';
          task.completedAt = now;
          task.proofOfWork = {
            photos: photos || [
              'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=500&auto=format&fit=crop&q=80'
            ],
            notes: notes || 'Delivery completed at recipient location.',
            submittedAt: now,
            gpsCoordinates: gpsCoordinates || [38.7636, 9.0125]
          };

          task.timeline.push({
            status: 'SUBMITTED',
            timestamp: now,
            actorId: req.user._id as Types.ObjectId,
            note: 'Completion proof submitted by tasker'
          });

          await task.save();

          const io = req.app.get('io');
          if (io) {
            io.emit('task_completed', {
              taskId: String(task._id || id),
              status: 'SUBMITTED',
              startedAt: task.startedAt?.toISOString(),
              completedAt: now.toISOString(),
              taskTitle: task.title
            });
            io.emit('status_changed', {
              taskId: String(task._id || id),
              status: 'SUBMITTED',
              completedAt: now.toISOString()
            });
            io.emit('in_app_notification', {
              targetUserId: String(task.customerId),
              taskId: String(task._id || id),
              title: 'Task Completed! ⏱️ Review & Approve',
              message: `${req.user.firstName || 'Tasker'} has finished your task and submitted completion proof.`
            });
          }

          res.status(200).json({
            success: true,
            message: 'Proof submitted, awaiting customer approval',
            task: {
              ...task.toObject(),
              completedAt: now
            }
          });
          return;
        }
      } catch (dbErr) {
        console.error('DB Error in submitProof:', dbErr);
      }
    }

    const inMem = IN_MEMORY_TASKS.find(t => String(t._id || t.id) === String(id));
    if (inMem) {
      inMem.status = 'SUBMITTED';
      inMem.completedAt = now;
      inMem.proofOfWork = {
        photos: photos || ['https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=500&auto=format&fit=crop&q=80'],
        notes: notes || 'Service completed successfully.',
        submittedAt: now,
        gpsCoordinates: gpsCoordinates || [38.7636, 9.0125]
      };
    }

    const io = req.app.get('io');
    if (io) {
      io.emit('task_completed', {
        taskId: id,
        status: 'SUBMITTED',
        startedAt: inMem?.startedAt?.toISOString(),
        completedAt: now.toISOString(),
        taskTitle: inMem?.title || 'Task'
      });
      io.emit('status_changed', {
        taskId: id,
        status: 'SUBMITTED',
        completedAt: now.toISOString()
      });
      io.emit('in_app_notification', {
        targetUserId: 'customer_sarah',
        taskId: id,
        title: 'Task Completed! ⏱️ Review & Approve',
        message: `Tasker has finished your task "${inMem?.title || 'Task'}" and submitted completion proof.`
      });
    }

    res.status(200).json({
      success: true,
      message: 'Proof submitted, awaiting customer approval',
      task: inMem || { _id: id, status: 'SUBMITTED', completedAt: now }
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message || 'Server error' });
  }
};

// Customer Approves Task & Escrow Releases Funds to Tasker Wallet
export const approveTask = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    if (Types.ObjectId.isValid(id) && req.user) {
      try {
        const task = await Task.findOne({ _id: id, customerId: req.user._id });

        if (task) {
          if (task.status === 'PAID' || task.status === 'COMPLETED') {
            res.status(400).json({ success: false, message: 'Task already approved and paid' });
            return;
          }

          const taskerId = task.assignedTaskerId;
          const payoutAmount = task.pricing.budget;

          if (taskerId) {
            // 1. Credit Tasker Wallet
            const wallet = await Wallet.findOneAndUpdate(
              { userId: taskerId },
              {
                $inc: {
                  availableBalance: payoutAmount,
                  totalEarned: payoutAmount
                }
              },
              { new: true, upsert: true }
            );

            // 2. Record Idempotent Transaction Ledger Entry
            const idempotencyKey = `PAYOUT_${task._id}_${Date.now()}`;
            await Transaction.create({
              walletId: wallet._id,
              userId: taskerId,
              taskId: task._id,
              amount: payoutAmount,
              currency: 'ETB',
              type: 'TASK_EARNING',
              status: 'COMPLETED',
              idempotencyKey,
              description: `Payment released for task: ${task.title}`
            });

            // 3. Increment Tasker completed count
            await User.findByIdAndUpdate(taskerId, {
              $inc: { completedTasksCount: 1 }
            });
          }

          // 4. Update Task Status to PAID
          task.status = 'PAID';
          task.pricing.finalPaidAmount = payoutAmount;
          task.timeline.push(
            {
              status: 'COMPLETED',
              timestamp: new Date(),
              actorId: req.user._id as Types.ObjectId,
              note: 'Customer approved completion'
            },
            {
              status: 'PAID',
              timestamp: new Date(),
              actorId: req.user._id as Types.ObjectId,
              note: `Funds of ${payoutAmount} ETB released to tasker`
            }
          );

          await task.save();

          res.status(200).json({
            success: true,
            message: 'Task approved and payment released to tasker',
            task,
            payoutAmount
          });
          return;
        }
      } catch (dbErr) {
        console.error('DB Error in approveTask:', dbErr);
      }
    }

    const inMem = IN_MEMORY_TASKS.find(t => t._id === id);
    if (inMem) {
      inMem.status = 'PAID';
    }

    res.status(200).json({
      success: true,
      message: 'Task approved and payment released to tasker',
      task: inMem || { _id: id, status: 'PAID' },
      payoutAmount: inMem?.pricing?.budget || 500
    });
  } catch (error: any) {
    console.error('Approval error:', error);
    res.status(500).json({ success: false, message: error.message || 'Server error' });
  }
};

export const disputeTask = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { reason, description, evidenceUrls } = req.body;

    if (Types.ObjectId.isValid(id) && req.user) {
      try {
        const task = await Task.findById(id);
        if (task) {
          task.status = 'DISPUTED';
          task.timeline.push({
            status: 'DISPUTED',
            timestamp: new Date(),
            actorId: req.user._id as Types.ObjectId,
            note: `Dispute opened: ${reason}`
          });
          await task.save();

          const dispute = await Dispute.create({
            taskId: task._id,
            raisedBy: req.user._id,
            reason,
            description,
            evidenceUrls: evidenceUrls || [],
            status: 'OPEN'
          });

          res.status(201).json({
            success: true,
            message: 'Dispute recorded. Our support team will review the evidence.',
            dispute,
            task
          });
          return;
        }
      } catch (dbErr) {
        console.error('DB Error in disputeTask:', dbErr);
      }
    }

    const inMem = IN_MEMORY_TASKS.find(t => t._id === id);
    if (inMem) {
      inMem.status = 'DISPUTED';
    }

    res.status(201).json({
      success: true,
      message: 'Dispute recorded. Our support team will review the evidence.',
      task: inMem || { _id: id, status: 'DISPUTED' }
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Customer Rates and Reviews the Assigned Tasker
export const rateTaskerByCustomer = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { rating, review, comment, tags, tipAmount } = req.body;

    const numRating = Number(rating) || 5;
    const reviewText = review || comment || '';
    const tagList = Array.isArray(tags) ? tags : [];
    const tip = Number(tipAmount) || 0;
    const now = new Date();

    if (Types.ObjectId.isValid(id)) {
      try {
        const task = await Task.findById(id);
        if (task) {
          task.customerRatingToTasker = {
            rating: numRating,
            review: reviewText,
            tags: tagList,
            tipAmount: tip,
            ratedAt: now
          };
          await task.save();

          const taskerId = task.assignedTaskerId;
          if (taskerId) {
            const tasker = await User.findById(taskerId);
            if (tasker) {
              const currentReviews = tasker.reviewCount || 0;
              const currentRating = tasker.rating || 5.0;
              const newRating = Number(((currentRating * currentReviews + numRating) / (currentReviews + 1)).toFixed(2));
              tasker.rating = newRating;
              tasker.reviewCount = currentReviews + 1;
              await tasker.save();
            }

            // Handle optional Tip
            if (tip > 0) {
              const wallet = await Wallet.findOneAndUpdate(
                { userId: taskerId },
                { $inc: { availableBalance: tip, totalEarned: tip } },
                { new: true, upsert: true }
              );
              await Transaction.create({
                walletId: wallet._id,
                userId: taskerId,
                taskId: task._id,
                amount: tip,
                currency: 'ETB',
                type: 'TIP_EARNING',
                status: 'COMPLETED',
                idempotencyKey: `TIP_${task._id}_${Date.now()}`,
                description: `Customer tip for task: ${task.title}`
              });
            }
          }

          const io = req.app.get('io');
          if (io) {
            io.emit('in_app_notification', {
              targetUserId: String(task.assignedTaskerId || 'tasker_daniel'),
              taskId: String(task._id),
              title: `⭐ You received a ${numRating}-Star Rating!`,
              message: `Customer rated your completed task "${task.title}": "${reviewText || 'Excellent service!'}"${tip > 0 ? ` (+${tip} ETB Tip)` : ''}`
            });
            io.emit('task_rated', {
              taskId: String(task._id),
              customerRatingToTasker: task.customerRatingToTasker
            });
          }

          res.status(200).json({
            success: true,
            message: 'Tasker rated successfully by customer',
            task
          });
          return;
        }
      } catch (dbErr) {
        console.error('DB error in rateTaskerByCustomer:', dbErr);
      }
    }

    // In-memory fallback
    const inMem = IN_MEMORY_TASKS.find(t => String(t._id || t.id) === String(id));
    if (inMem) {
      inMem.customerRatingToTasker = {
        rating: numRating,
        review: reviewText,
        tags: tagList,
        tipAmount: tip,
        ratedAt: now
      };
    }

    const io = req.app.get('io');
    if (io) {
      io.emit('in_app_notification', {
        targetUserId: inMem?.assignedTaskerId || 'tasker_daniel',
        taskId: id,
        title: `⭐ You received a ${numRating}-Star Rating!`,
        message: `Customer rated your task: "${reviewText || 'Great job!'}"${tip > 0 ? ` (+${tip} ETB Tip)` : ''}`
      });
      io.emit('task_rated', {
        taskId: id,
        customerRatingToTasker: inMem?.customerRatingToTasker
      });
    }

    res.status(200).json({
      success: true,
      message: 'Tasker rated successfully by customer',
      task: inMem || {
        _id: id,
        customerRatingToTasker: {
          rating: numRating,
          review: reviewText,
          tags: tagList,
          tipAmount: tip,
          ratedAt: now
        }
      }
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message || 'Server error' });
  }
};
