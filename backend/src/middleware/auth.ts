import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { User, IUser } from '../models/User';

export interface AuthRequest extends Request {
  user?: IUser;
}

export const authenticateJWT = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  const authHeader = req.headers.authorization;
  const secret = process.env.JWT_SECRET || 'finish_super_secret_jwt_key_2026_production';

  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.split(' ')[1];
    if (token && token !== 'mock_token' && token !== 'null' && token !== 'undefined') {
      try {
        const decoded = jwt.verify(token, secret) as { userId: string };
        const user = await User.findById(decoded.userId);
        if (user) {
          req.user = user;
          next();
          return;
        }
      } catch (_) {}
    }
  }

  res.status(401).json({ success: false, message: 'Unauthorized. Please log in.' });
};

export const optionalAuth = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  const authHeader = req.headers.authorization;
  const secret = process.env.JWT_SECRET || 'finish_super_secret_jwt_key_2026_production';

  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.split(' ')[1];
    if (token && token !== 'mock_token' && token !== 'null' && token !== 'undefined') {
      try {
        const decoded = jwt.verify(token, secret) as { userId: string };
        const user = await User.findById(decoded.userId);
        if (user) {
          req.user = user;
        }
      } catch (_) {}
    }
  }
  next();
};
