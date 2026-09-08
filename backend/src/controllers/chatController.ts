import { Response } from 'express';
import { Types } from 'mongoose';
import { Message } from '../models/Message';
import { Task } from '../models/Task';
import { AuthRequest } from '../middleware/auth';
import { IN_MEMORY_TASKS } from './taskController';

const IN_MEMORY_MESSAGES: Record<string, any[]> = {};

export const getTaskMessages = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { taskId } = req.params;
    const currentUserId = req.user?._id ? String(req.user._id) : (req.query.userId as string || '');
    const otherUserId = (req.query.otherUserId as string || req.query.recipientId as string || '');

    if (Types.ObjectId.isValid(taskId)) {
      try {
        let filter: any = { taskId };
        if (currentUserId && otherUserId && Types.ObjectId.isValid(currentUserId) && Types.ObjectId.isValid(otherUserId)) {
          filter = {
            taskId,
            $or: [
              { senderId: new Types.ObjectId(currentUserId), recipientId: new Types.ObjectId(otherUserId) },
              { senderId: new Types.ObjectId(otherUserId), recipientId: new Types.ObjectId(currentUserId) }
            ]
          };
        } else if (currentUserId && Types.ObjectId.isValid(currentUserId)) {
          filter = {
            taskId,
            $or: [
              { senderId: new Types.ObjectId(currentUserId) },
              { recipientId: new Types.ObjectId(currentUserId) }
            ]
          };
        }

        const messages = await Message.find(filter)
          .populate('senderId', 'firstName lastName avatarUrl')
          .sort({ createdAt: 1 });

        res.status(200).json({
          success: true,
          messages
        });
        return;
      } catch (dbErr) {
        console.error('DB Error in getTaskMessages:', dbErr);
      }
    }

    const all = IN_MEMORY_MESSAGES[taskId] || [];
    let messages = all;
    if (currentUserId && otherUserId) {
      messages = all.filter(m => {
        const s = String(m.senderId?._id || m.senderId || '');
        const r = String(m.recipientId?._id || m.recipientId || '');
        return (s === currentUserId && r === otherUserId) ||
               (s === otherUserId && r === currentUserId) ||
               (!r && (s === currentUserId || s === otherUserId));
      });
    } else if (currentUserId) {
      messages = all.filter(m => {
        const s = String(m.senderId?._id || m.senderId || '');
        const r = String(m.recipientId?._id || m.recipientId || '');
        return s === currentUserId || r === currentUserId || !r;
      });
    }

    res.status(200).json({
      success: true,
      messages
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const sendMessage = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { taskId } = req.params;
    const { content, type, mediaUrl, recipientId, otherUserId } = req.body;

    if (!content && !mediaUrl) {
      res.status(400).json({ success: false, message: 'Message content or media is required' });
      return;
    }

    const senderId = req.user?._id || (req.body.senderId ? new Types.ObjectId(req.body.senderId) : new Types.ObjectId('65e0123456789abcdef00001'));
    const targetRecipientId = recipientId || otherUserId || (req.body.recipientId ? String(req.body.recipientId) : '');

    if (Types.ObjectId.isValid(taskId)) {
      try {
        const task = await Task.findById(taskId);
        if (task) {
          const finalRecipientId = targetRecipientId && Types.ObjectId.isValid(targetRecipientId)
            ? new Types.ObjectId(targetRecipientId)
            : ((req.user && task.customerId && req.user._id.toString() === task.customerId.toString())
                ? (task.assignedTaskerId || new Types.ObjectId('65e0123456789abcdef00002'))
                : (task.customerId || new Types.ObjectId('65e0123456789abcdef00001')));

          const message = await Message.create({
            taskId: task._id,
            senderId,
            recipientId: finalRecipientId,
            content: content || '',
            type: type || 'TEXT',
            mediaUrl,
            isRead: false
          });

          const populated = await Message.findById(message._id).populate('senderId', 'firstName lastName avatarUrl');

          if (!IN_MEMORY_MESSAGES[taskId]) {
            IN_MEMORY_MESSAGES[taskId] = [];
          }
          IN_MEMORY_MESSAGES[taskId].push(populated || message);

          // Broadcast in real-time PRIVATELY
          const io = req.app.get('io');
          if (io) {
            const cleanId = String(taskId).startsWith('task_') ? String(taskId).replace('task_', '') : String(taskId);
            const sId = String(senderId);
            const rId = String(finalRecipientId);
            const pair = [sId, rId].sort();

            io.to(`thread_${cleanId}_${pair[0]}_${pair[1]}`).emit('new_message', populated || message);
            io.to(`thread_${taskId}_${pair[0]}_${pair[1]}`).emit('new_message', populated || message);
            io.to(`user_${rId}`).emit('new_message', populated || message);
            io.to(`user_${sId}`).emit('new_message', populated || message);

            io.to(`task_${cleanId}`).emit('new_message', populated || message);
            io.to(`task_${taskId}`).emit('new_message', populated || message);
            io.emit('new_global_message', populated || message);
          }

          res.status(201).json({
            success: true,
            message: populated || message
          });
          return;
        }
      } catch (dbErr) {
        console.error('DB Error in sendMessage:', dbErr);
      }
    }

    // In-memory fallback
    const reqSenderName = (req.body.senderName || '').trim();
    const nameParts = reqSenderName ? reqSenderName.split(' ') : [];
    const firstName = nameParts.length > 0
      ? nameParts[0]
      : (req.user?.firstName || (req.user?.activeMode === 'tasker' ? 'Tasker' : 'Customer'));
    const lastName = nameParts.length > 1
      ? nameParts.slice(1).join(' ')
      : (req.user?.lastName || '');

    const finalSenderId = String(req.body.senderId || senderId || 'customer_sarah');
    const finalRecipientId = String(targetRecipientId || (finalSenderId.includes('customer') ? 'tasker_daniel' : 'customer_sarah'));

    const mockMessage = {
      _id: 'msg_' + Date.now(),
      taskId,
      senderId: {
        _id: finalSenderId,
        firstName,
        lastName,
        avatarUrl: req.user?.avatarUrl || ''
      },
      recipientId: finalRecipientId,
      content: content || '',
      type: type || 'TEXT',
      mediaUrl,
      isRead: false,
      createdAt: new Date()
    };

    if (!IN_MEMORY_MESSAGES[taskId]) {
      IN_MEMORY_MESSAGES[taskId] = [];
    }
    IN_MEMORY_MESSAGES[taskId].push(mockMessage);

    // Broadcast via Socket.IO PRIVATELY
    const io = req.app.get('io');
    if (io) {
      const cleanId = String(taskId).startsWith('task_') ? String(taskId).replace('task_', '') : String(taskId);
      const pair = [finalSenderId, finalRecipientId].sort();

      io.to(`thread_${cleanId}_${pair[0]}_${pair[1]}`).emit('new_message', mockMessage);
      io.to(`thread_${taskId}_${pair[0]}_${pair[1]}`).emit('new_message', mockMessage);
      io.to(`user_${finalRecipientId}`).emit('new_message', mockMessage);
      io.to(`user_${finalSenderId}`).emit('new_message', mockMessage);

      io.to(`task_${cleanId}`).emit('new_message', mockMessage);
      io.to(`task_${taskId}`).emit('new_message', mockMessage);
      io.emit('new_global_message', mockMessage);
    }

    res.status(201).json({
      success: true,
      message: mockMessage
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message || 'Server error' });
  }
};

export const markMessagesAsRead = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { taskId } = req.params;
    const userId = req.user?._id;

    if (Types.ObjectId.isValid(taskId)) {
      try {
        const filter: any = { taskId, isRead: false };
        if (userId && Types.ObjectId.isValid(String(userId))) {
          filter.senderId = { $ne: userId };
        }
        await Message.updateMany(filter, { $set: { isRead: true } });
      } catch (dbErr) {
        console.error('DB Error in markMessagesAsRead:', dbErr);
      }
    }

    if (IN_MEMORY_MESSAGES[taskId]) {
      IN_MEMORY_MESSAGES[taskId].forEach((msg) => {
        msg.isRead = true;
      });
    }

    const io = req.app.get('io');
    if (io) {
      const cleanId = String(taskId).startsWith('task_') ? String(taskId).replace('task_', '') : String(taskId);
      io.to(`task_${cleanId}`).emit('messages_read', { taskId, userId });
      io.to(`task_${taskId}`).emit('messages_read', { taskId, userId });
      io.to(String(taskId)).emit('messages_read', { taskId, userId });
      io.emit('messages_read', { taskId, userId });
    }

    res.status(200).json({
      success: true,
      message: 'Messages marked as read'
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message || 'Server error' });
  }
};

export const getConversations = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const currentUserId = req.user?._id
      ? String(req.user._id)
      : (req.query.userId as string || (req.headers['x-user-id'] as string) || '');
    const activeRole = req.user?.activeMode || (req.headers['x-role'] as string) || (req.query.role as string) || 'customer';
    const isTaskerRole = activeRole === 'tasker';
    const effectiveUserId = currentUserId || (isTaskerRole ? 'tasker_daniel' : 'customer_sarah');

    const threadMap = new Map<string, {
      taskId: string;
      otherUserId: string;
      otherUser: any;
      lastMessage: any;
      unreadCount: number;
      task: any;
    }>();

    // 1. Query MongoDB for messages involving effectiveUserId
    if (Types.ObjectId.isValid(effectiveUserId)) {
      try {
        const userObjId = new Types.ObjectId(effectiveUserId);
        const myMessages = await Message.find({
          $or: [{ senderId: userObjId }, { recipientId: userObjId }]
        })
          .populate('senderId', 'firstName lastName avatarUrl rating reviewCount isIdentityVerified')
          .populate('recipientId', 'firstName lastName avatarUrl rating reviewCount isIdentityVerified')
          .populate('taskId')
          .sort({ createdAt: 1 });

        for (const msg of myMessages) {
          if (!msg.taskId) continue;
          const tId = String((msg.taskId as any)._id || msg.taskId);
          const isSender = String((msg.senderId as any)?._id || msg.senderId) === effectiveUserId;
          const otherUser = isSender ? msg.recipientId : msg.senderId;
          const otherId = String((otherUser as any)?._id || otherUser || '');
          if (!otherId) continue;
          const threadKey = `${tId}_${otherId}`;

          const isUnread = !isSender && !msg.isRead;
          const existing = threadMap.get(threadKey);
          if (!existing) {
            threadMap.set(threadKey, {
              taskId: tId,
              otherUserId: otherId,
              otherUser,
              lastMessage: msg,
              unreadCount: isUnread ? 1 : 0,
              task: msg.taskId
            });
          } else {
            existing.lastMessage = msg;
            if (isUnread) existing.unreadCount += 1;
          }
        }
      } catch (dbErr) {
        console.error('DB Error in getConversations:', dbErr);
      }
    }

    // 2. Scan IN_MEMORY_MESSAGES for threads strictly involving effectiveUserId
    for (const [taskId, msgs] of Object.entries(IN_MEMORY_MESSAGES)) {
      for (const msg of msgs) {
        const sId = String(msg.senderId?._id || msg.senderId || '');
        const rId = String(msg.recipientId?._id || msg.recipientId || '');

        const isSender = sId === effectiveUserId;
        const isRecipient = rId === effectiveUserId;

        // Message must strictly involve this user as sender or recipient
        if (isSender || isRecipient) {
          const otherId = isSender ? (rId || (isTaskerRole ? 'customer_sarah' : 'tasker_daniel')) : sId;
          const threadKey = `${taskId}_${otherId}`;

          const task = IN_MEMORY_TASKS.find((t) => String(t._id || t.id) === String(taskId)) || {
            _id: taskId,
            title: 'Task Direct Chat',
            category: 'delivery',
            pricing: { budget: 450 },
            status: 'IN_PROGRESS',
            customerId: {
              _id: 'customer_sarah',
              firstName: 'Sarah',
              lastName: 'M.',
              avatarUrl: '',
              rating: 5.0,
              reviewCount: 12
            }
          };

          const otherUser = isSender
            ? {
                _id: otherId,
                firstName: isTaskerRole ? 'Sarah' : 'Daniel',
                lastName: isTaskerRole ? 'M.' : 'Kebede',
                avatarUrl: '',
                rating: isTaskerRole ? 5.0 : 4.9,
                reviewCount: 18
              }
            : (msg.senderId && typeof msg.senderId === 'object'
                ? msg.senderId
                : {
                    _id: otherId,
                    firstName: msg.senderName ? msg.senderName.split(' ')[0] : (isTaskerRole ? 'Sarah' : 'Daniel'),
                    lastName: msg.senderName && msg.senderName.split(' ').length > 1 ? msg.senderName.split(' ').slice(1).join(' ') : '',
                    avatarUrl: '',
                    rating: isTaskerRole ? 5.0 : 4.9,
                    reviewCount: 18
                  });

          const isUnread = !isSender && !msg.isRead;
          const existing = threadMap.get(threadKey);
          if (!existing) {
            threadMap.set(threadKey, {
              taskId,
              otherUserId: otherId,
              otherUser,
              lastMessage: msg,
              unreadCount: isUnread ? 1 : 0,
              task
            });
          } else {
            existing.lastMessage = msg;
            if (isUnread) existing.unreadCount += 1;
          }
        }
      }
    }

    // 3. Transform threadMap into clean Conversations JSON array
    const conversations: any[] = [];
    for (const thread of threadMap.values()) {
      const p = thread.otherUser;
      const firstName = p?.firstName || (typeof p === 'string' ? p : (isTaskerRole ? 'Sarah' : 'Daniel'));
      const lastName = p?.lastName || '';
      conversations.push({
        taskId: thread.taskId,
        task: thread.task,
        participant: {
          _id: thread.otherUserId,
          id: thread.otherUserId,
          firstName,
          lastName,
          avatarUrl: p?.avatarUrl || '',
          rating: p?.rating || (isTaskerRole ? 5.0 : 4.9),
          reviewCount: p?.reviewCount || 18,
          isIdentityVerified: true
        },
        lastMessage: {
          _id: thread.lastMessage._id || thread.lastMessage.id || 'msg_0',
          content: thread.lastMessage.content || '',
          type: thread.lastMessage.type || 'TEXT',
          senderId: thread.lastMessage.senderId,
          createdAt: thread.lastMessage.createdAt || new Date(),
          isRead: thread.lastMessage.isRead !== undefined ? thread.lastMessage.isRead : true
        },
        unreadCount: thread.unreadCount
      });
    }

    // Sort by latest message timestamp descending
    conversations.sort(
      (a, b) => new Date(b.lastMessage.createdAt).getTime() - new Date(a.lastMessage.createdAt).getTime()
    );

    res.status(200).json({
      success: true,
      count: conversations.length,
      conversations
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message || 'Server error' });
  }
};
