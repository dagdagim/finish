import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';
import { User } from './models/User';
import { Task } from './models/Task';
import { Offer } from './models/Offer';
import { Wallet } from './models/Wallet';
import { Transaction } from './models/Transaction';
import { Message } from './models/Message';

dotenv.config();

const MONGODB_URL = process.env.MONGODB_URL || 'mongodb+srv://dagimbekele_db_user:TDu5Uw3qmife9GUx@cluster0.bjzjflu.mongodb.net/finish_marketplace?appName=Cluster0';

async function seed() {
  try {
    console.log('[Seed] Connecting to MongoDB Atlas...');
    await mongoose.connect(MONGODB_URL);
    console.log('[Seed] Connected. Cleaning existing collections...');

    await Promise.all([
      User.deleteMany({}),
      Task.deleteMany({}),
      Offer.deleteMany({}),
      Wallet.deleteMany({}),
      Transaction.deleteMany({}),
      Message.deleteMany({})
    ]);

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash('Finish2026!', salt);

    console.log('[Seed] Creating realistic accounts...');

    // 1. Customer: Sarah M.
    const sarah = await User.create({
      firstName: 'Sarah',
      lastName: 'Mamo',
      email: 'sarah@finish.et',
      phone: '+251911223344',
      passwordHash,
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80',
      role: 'both',
      activeMode: 'customer',
      rating: 4.9,
      reviewCount: 12,
      completedTasksCount: 8,
      isPhoneVerified: true,
      isIdentityVerified: true
    });

    // 2. Tasker: Daniel K.
    const daniel = await User.create({
      firstName: 'Daniel',
      lastName: 'Kebede',
      email: 'daniel@finish.et',
      phone: '+251912345678',
      passwordHash,
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80',
      role: 'both',
      activeMode: 'tasker',
      rating: 4.9,
      reviewCount: 94,
      completedTasksCount: 128,
      isPhoneVerified: true,
      isIdentityVerified: true,
      taskerProfile: {
        bio: 'Fast, reliable courier and handy helper in Bole & Kazanchis. Top rated with 99% completion rate.',
        skills: ['Delivery', 'Pickup', 'Shopping', 'Assembly'],
        serviceRadiusKm: 15,
        isAvailableNow: true,
        level: 'PRO',
        completionRate: 99,
        onTimeRate: 98
      }
    });

    // 3. Tasker: Michael A.
    const michael = await User.create({
      firstName: 'Michael',
      lastName: 'Alemu',
      email: 'michael@finish.et',
      phone: '+251922334455',
      passwordHash,
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&auto=format&fit=crop&q=80',
      role: 'tasker',
      activeMode: 'tasker',
      rating: 4.7,
      reviewCount: 52,
      completedTasksCount: 85,
      isPhoneVerified: true,
      isIdentityVerified: true,
      taskerProfile: {
        bio: 'Home repairs and small errands specialist.',
        skills: ['Moving', 'Assembly', 'Cleaning'],
        serviceRadiusKm: 10,
        isAvailableNow: true,
        level: 'ACTIVE',
        completionRate: 97,
        onTimeRate: 95
      }
    });

    // 4. Tasker: Abel T.
    const abel = await User.create({
      firstName: 'Abel',
      lastName: 'Tadesse',
      email: 'abel@finish.et',
      phone: '+251933445566',
      passwordHash,
      avatarUrl: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=400&auto=format&fit=crop&q=80',
      role: 'tasker',
      activeMode: 'tasker',
      rating: 5.0,
      reviewCount: 31,
      completedTasksCount: 42,
      isPhoneVerified: true,
      isIdentityVerified: true,
      taskerProfile: {
        bio: 'Careful handling for documents, fragile items, and quick errands.',
        skills: ['Delivery', 'Pickup', 'Tech Help'],
        serviceRadiusKm: 20,
        isAvailableNow: true,
        level: 'PRO',
        completionRate: 100,
        onTimeRate: 99
      }
    });

    console.log('[Seed] Initializing wallets & balances...');

    // Wallets
    const danielWallet = await Wallet.create({
      userId: daniel._id,
      availableBalance: 2450,
      pendingBalance: 700,
      totalEarned: 18450,
      currency: 'ETB'
    });

    await Wallet.create({
      userId: sarah._id,
      availableBalance: 5000,
      pendingBalance: 500,
      totalEarned: 0,
      currency: 'ETB'
    });

    // Transactions for Daniel
    await Transaction.create([
      {
        walletId: danielWallet._id,
        userId: daniel._id,
        amount: 500,
        currency: 'ETB',
        type: 'TASK_EARNING',
        status: 'COMPLETED',
        idempotencyKey: 'TX_SEED_1',
        description: 'Package delivery · Completed'
      },
      {
        walletId: danielWallet._id,
        userId: daniel._id,
        amount: -1000,
        currency: 'ETB',
        type: 'WITHDRAWAL',
        status: 'COMPLETED',
        idempotencyKey: 'TX_SEED_2',
        description: 'Withdrawal to Telebirr (0912***678)'
      },
      {
        walletId: danielWallet._id,
        userId: daniel._id,
        amount: 350,
        currency: 'ETB',
        type: 'TASK_EARNING',
        status: 'COMPLETED',
        idempotencyKey: 'TX_SEED_3',
        description: 'Document pickup & drop-off'
      }
    ]);

    console.log('[Seed] Creating realistic marketplace tasks in Addis Ababa...');

    // Task 1: Package Pickup (Bole -> Kazanchis) - Assigned to Daniel
    const task1 = await Task.create({
      customerId: sarah._id,
      assignedTaskerId: daniel._id,
      title: 'Package Pickup',
      category: 'delivery',
      description: 'Pick up the package from the store and deliver to the customer. Handle with care.',
      quantity: 1,
      specialInstructions: 'Please call recipient 5 minutes before arriving.',
      mediaUrls: [
        'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=500&auto=format&fit=crop&q=80'
      ],
      pickupLocation: {
        address: 'Bole Medhanialem, Addis Ababa',
        coordinates: [38.7891, 8.9953],
        instructions: 'Near Edna Mall entrance'
      },
      dropoffLocation: {
        address: 'Kazanchis, Addis Ababa',
        coordinates: [38.7636, 9.0125],
        instructions: 'Apartment Building 4, 3rd Floor'
      },
      schedule: {
        type: 'today',
        windowText: 'Today · Before 5 PM',
        date: new Date(),
        windowStart: '16:00',
        windowEnd: '17:00'
      },
      pricing: {
        budget: 500,
        currency: 'ETB',
        pricingType: 'fixed',
        suggestedPrice: 450,
        platformFee: 50
      },
      status: 'IN_PROGRESS',
      distanceKm: 2.4,
      estimatedDurationMin: 35,
      timeline: [
        { status: 'POSTED', timestamp: new Date(Date.now() - 3600000), note: 'Task posted' },
        { status: 'ACCEPTED', timestamp: new Date(Date.now() - 2400000), note: 'Daniel accepted task' },
        { status: 'IN_PROGRESS', timestamp: new Date(Date.now() - 1200000), note: 'Daniel started delivery' }
      ]
    });

    // Task 2: Pick up documents (Open for offers)
    const task2 = await Task.create({
      customerId: sarah._id,
      title: 'Pick up documents',
      category: 'pickup',
      description: 'Pick up legal contract documents from the office and deliver to the address. Please handle with extreme care.',
      quantity: 1,
      specialInstructions: 'Keep in dry folder',
      mediaUrls: [
        'https://images.unsplash.com/photo-1586281380349-632531db7ed4?w=500&auto=format&fit=crop&q=80'
      ],
      pickupLocation: {
        address: 'Office, Bole, Addis Ababa',
        coordinates: [38.7865, 8.9982]
      },
      dropoffLocation: {
        address: 'Kazanchis, Addis Ababa',
        coordinates: [38.7636, 9.0125]
      },
      schedule: {
        type: 'today',
        windowText: 'Today · 4:00 PM - 6:00 PM',
        date: new Date()
      },
      pricing: {
        budget: 450,
        currency: 'ETB',
        pricingType: 'negotiable',
        suggestedPrice: 450,
        platformFee: 45
      },
      status: 'OPEN',
      distanceKm: 2.6,
      estimatedDurationMin: 30,
      timeline: [
        { status: 'POSTED', timestamp: new Date(), note: 'Task posted by customer' }
      ]
    });

    // Task 3: Furniture Assembly (Sarbet) - Open with multiple offers
    const task3 = await Task.create({
      customerId: sarah._id,
      title: 'Move small table & assemble chairs',
      category: 'assembly',
      description: 'Need assistance assembling 4 dining chairs and moving a wooden side table into the living room.',
      quantity: 1,
      specialInstructions: 'Allen keys provided. Bring a small screwdriver if possible.',
      mediaUrls: [
        'https://images.unsplash.com/photo-1538688525198-9b88f6f53126?w=500&auto=format&fit=crop&q=80'
      ],
      pickupLocation: {
        address: 'Sarbet, Addis Ababa',
        coordinates: [38.7369, 8.9961]
      },
      schedule: {
        type: 'tomorrow',
        windowText: 'Tomorrow · 10:00 AM',
        date: new Date(Date.now() + 86400000)
      },
      pricing: {
        budget: 700,
        currency: 'ETB',
        pricingType: 'negotiable',
        suggestedPrice: 650,
        platformFee: 70
      },
      status: 'OFFERING',
      distanceKm: 4.8,
      estimatedDurationMin: 75,
      timeline: [
        { status: 'POSTED', timestamp: new Date(Date.now() - 7200000), note: 'Task posted' }
      ]
    });

    // Create Offers on Task 3
    await Offer.create([
      {
        taskId: task3._id,
        taskerId: daniel._id,
        offeredAmount: 650,
        note: 'I have my own tools and can be there at 10 AM sharp.',
        status: 'PENDING'
      },
      {
        taskId: task3._id,
        taskerId: michael._id,
        offeredAmount: 700,
        note: 'Furniture assembly specialist with 80+ finished jobs.',
        status: 'PENDING'
      },
      {
        taskId: task3._id,
        taskerId: abel._id,
        offeredAmount: 750,
        note: '5-star rated, can bring a helper if table is heavy.',
        status: 'PENDING'
      }
    ]);
    task3.offersCount = 3;
    await task3.save();

    // Task 4: Completed task for Recent Tasks view
    await Task.create({
      customerId: sarah._id,
      assignedTaskerId: daniel._id,
      title: 'Furniture Assembly',
      category: 'assembly',
      description: 'Assembled TV stand unit in living room.',
      quantity: 1,
      pickupLocation: {
        address: 'Bole, Addis Ababa',
        coordinates: [38.7891, 8.9953]
      },
      schedule: {
        type: 'today',
        windowText: 'Completed · 2 days ago'
      },
      pricing: {
        budget: 600,
        currency: 'ETB',
        pricingType: 'fixed',
        suggestedPrice: 600,
        platformFee: 60,
        finalPaidAmount: 600
      },
      status: 'PAID',
      distanceKm: 1.5,
      estimatedDurationMin: 45,
      timeline: [
        { status: 'POSTED', timestamp: new Date(Date.now() - 172800000) },
        { status: 'ACCEPTED', timestamp: new Date(Date.now() - 172000000) },
        { status: 'COMPLETED', timestamp: new Date(Date.now() - 168000000) },
        { status: 'PAID', timestamp: new Date(Date.now() - 167000000) }
      ]
    });

    // Task 5: Grocery Shopping (Piassa)
    await Task.create({
      customerId: sarah._id,
      title: 'Buy fresh groceries & fruits',
      category: 'shopping',
      description: 'Purchase fresh vegetables and dairy from local market and deliver to home.',
      quantity: 1,
      pickupLocation: {
        address: 'Piassa, Addis Ababa',
        coordinates: [38.7525, 9.0354]
      },
      dropoffLocation: {
        address: 'Bole, Addis Ababa',
        coordinates: [38.7891, 8.9953]
      },
      schedule: {
        type: 'asap',
        windowText: 'ASAP · Within 1 hour'
      },
      pricing: {
        budget: 350,
        currency: 'ETB',
        pricingType: 'fixed',
        suggestedPrice: 350,
        platformFee: 35
      },
      status: 'OPEN',
      distanceKm: 5.2,
      estimatedDurationMin: 40
    });

    console.log('[Seed] Creating initial messages for Task 1...');

    await Message.create([
      {
        taskId: task1._id,
        senderId: daniel._id,
        recipientId: sarah._id,
        content: "Hi Sarah, I'm on my way to the pickup location.",
        type: 'TEXT',
        isRead: true,
        createdAt: new Date(Date.now() - 900000)
      },
      {
        taskId: task1._id,
        senderId: sarah._id,
        recipientId: daniel._id,
        content: 'Great! Let me know when you arrive.',
        type: 'TEXT',
        isRead: true,
        createdAt: new Date(Date.now() - 600000)
      }
    ]);

    console.log('==============================================');
    console.log('  FINISH Marketplace Seed Completed Successfully!');
    console.log(`  Customer: sarah@finish.et (Password: Finish2026!)`);
    console.log(`  Tasker:   daniel@finish.et (Password: Finish2026!)`);
    console.log('==============================================');

    await mongoose.disconnect();
    process.exit(0);
  } catch (err) {
    console.error('[Seed] Error during seeding:', err);
    process.exit(1);
  }
}

seed();
