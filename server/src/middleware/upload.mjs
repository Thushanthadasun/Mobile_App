import multer from "multer"; // Added multer import
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from "path"; // Re-added path import for fileFilter

dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_ANON_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

// File filter to accept only images
const fileFilter = (req, file, cb) => {
  const allowedFileTypes = /\.(jpeg|jpg|png|gif)$/i;
  const allowedMimeTypes = [
    "image/jpeg",
    "image/png",
    "image/gif",
  ];

  const extname = allowedFileTypes.test(path.extname(file.originalname).toLowerCase());
  const mimetype = allowedMimeTypes.includes(file.mimetype);

  if (extname && mimetype) {
    cb(null, true);
  } else {
    console.log("File rejected:", {
      originalname: file.originalname,
      mimetype: file.mimetype,
      extname: path.extname(file.originalname),
    });
    cb(new Error("Images Only! (jpeg, jpg, png, gif)"), false);
  }
};

// Initialize multer for memory storage (since we'll upload to Supabase)
const upload = multer({
  storage: multer.memoryStorage(), // Use memory storage instead of disk
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB max file size
  fileFilter: fileFilter,
});

// Function to upload file to Supabase
const uploadToSupabase = async (file) => {
  const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
  const fileName = `${uniqueSuffix}${path.extname(file.originalname).toLowerCase()}`;
  
  const { data, error } = await supabase.storage
    .from('vehicle-images') // Supabase bucket name
    .upload(fileName, file.buffer, {
      contentType: file.mimetype,
    });

  if (error) {
    console.error('Supabase upload error:', error.message);
    throw new Error(`Failed to upload image to Supabase: ${error.message}`);
  }

  // Get the public URL for the uploaded file
  const { publicUrl } = supabase.storage
    .from('vehicle-images')
    .getPublicUrl(fileName).data;

  return publicUrl;
};

export { upload, uploadToSupabase };
