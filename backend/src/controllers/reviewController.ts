import { Response } from 'express';
import { Review } from '../models/Review';
import { User } from '../models/User';
import { Task } from '../models/Task';
import { AuthRequest } from '../middleware/auth';

export const submitReview = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const { taskId, revieweeId, rating, tags, comment } = req.body;

    if (!taskId || !revieweeId || !rating) {
      res.status(400).json({ success: false, message: 'Task ID, reviewee ID, and rating are required' });
      return;
    }

    const review = await Review.create({
      taskId,
      reviewerId: req.user._id,
      revieweeId,
      rating: Number(rating),
      tags: tags || [],
      comment: comment || ''
    });

    // Recalculate reviewee average rating
    const allReviews = await Review.find({ revieweeId });
    const avgRating = allReviews.reduce((sum, r) => sum + r.rating, 0) / allReviews.length;

    await User.findByIdAndUpdate(revieweeId, {
      rating: Math.round(avgRating * 10) / 10,
      reviewCount: allReviews.length
    });

    res.status(201).json({
      success: true,
      message: 'Review submitted successfully',
      review
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};
