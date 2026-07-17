-- Seed data for Gearsh MVP

-- Insert sample users
INSERT OR IGNORE INTO users (id, email, password_hash, user_type, first_name, last_name, display_name, profile_picture_url, location, country, bio, is_verified) VALUES
('user_1', 'yde@gearsh.com', '$2a$10$dummy_hash', 'artist', NULL, NULL, 'Y.D.E', 'assets/images/artists/yde.png', 'Louis Trichardt', 'South Africa', 'Emerging hip hop artist from Louis Trichardt', 1),
('user_2', 'zj90@gearsh.com', '$2a$10$dummy_hash', 'artist', NULL, NULL, 'ZJ90', 'assets/images/artists/ZJ90.jpg', 'Johannesburg', 'South Africa', 'DJ blending house and amapiano into high-energy sets', 1),
('user_3', 'rixelton@gearsh.com', '$2a$10$dummy_hash', 'artist', NULL, NULL, 'Rix Elton', 'assets/images/artists/rixelton.jpg', 'Johannesburg', 'South Africa', 'Amapiano DJ built for club floors and private events', 1),
('user_4', 'empressngqama@gearsh.com', '$2a$10$dummy_hash', 'artist', NULL, NULL, 'Empress Ngqama', 'assets/images/artists/empress-ngqama.jpg', 'Eastern Cape', 'South Africa', 'Afro-soul and reggae vocalist with a commanding live presence', 1),
('user_5', 'dripmaker@gearsh.com', '$2a$10$dummy_hash', 'artist', NULL, NULL, 'Dripmaker', 'assets/images/artists/dripmaker.png', 'Thohoyandou', 'South Africa', 'Fashion designer crafting standout looks for artists and events', 1),
('user_6', 'client1@example.com', '$2a$10$dummy_hash', 'client', 'John', 'Doe', NULL, NULL, 'Cape Town', 'South Africa', NULL, 0),
('user_7', 'client2@example.com', '$2a$10$dummy_hash', 'client', 'Jane', 'Smith', NULL, NULL, 'Durban', 'South Africa', NULL, 0);

-- Insert artist profiles
INSERT OR IGNORE INTO artist_profiles (id, user_id, category, genre, base_rate, hourly_rate, years_experience, skills, is_trending, avg_rating, total_reviews) VALUES
('artist_1', 'user_1', 'Hip Hop', 'Hip Hop', 3000, 3000, 1, '["Rapping", "Songwriting", "Live Performance"]', 1, 4.8, 12),
('artist_2', 'user_2', 'DJ', 'House · Amapiano', 3500, 3500, 3, '["DJ", "Mixing", "Live Performance"]', 1, 4.8, 18),
('artist_3', 'user_3', 'DJ', 'Amapiano', 2000, 2000, 2, '["DJ", "Amapiano", "Live Performance"]', 0, 4.7, 9),
('artist_4', 'user_4', 'Vocalist', 'Afro-Soul', 4500, 4500, 4, '["Vocals", "Songwriting", "Live Performance"]', 0, 4.9, 15),
('artist_5', 'user_5', 'Fashion', 'Fashion Design', 3500, 3500, 3, '["Fashion Design", "Styling", "Wardrobe"]', 0, 4.8, 11);

-- Insert services
INSERT OR IGNORE INTO services (id, artist_id, name, description, price, duration_hours) VALUES
('svc_1', 'artist_1', 'Live Performance', 'Live hip hop set for events and club nights', 3000, 1),
('svc_2', 'artist_2', 'Club DJ Set', 'High-energy house and amapiano DJ set', 3500, 2),
('svc_3', 'artist_3', 'Club Set', '2-hour amapiano set for clubs and lounges', 2000, 2),
('svc_4', 'artist_4', 'Live Performance', 'Afro-soul live performance with full vocals', 4500, 1),
('svc_5', 'artist_5', 'Event Styling', 'Custom styling and wardrobe for events and shoots', 3500, 4);

-- Insert sample bookings
INSERT OR IGNORE INTO bookings (id, client_id, artist_id, service_id, event_date, event_time, event_location, event_type, duration_hours, total_price, status) VALUES
('book_1', 'user_6', 'artist_2', 'svc_2', '2025-01-15', '20:00', 'Taboo Club, Johannesburg', 'Club Night', 2, 3500, 'confirmed'),
('book_2', 'user_7', 'artist_4', 'svc_4', '2025-02-20', '18:00', 'East London ICC', 'Live Show', 1, 4500, 'pending'),
('book_3', 'user_6', 'artist_5', 'svc_5', '2025-01-25', '14:00', 'Sandton Convention Centre', 'Corporate Event', 4, 3500, 'confirmed');

-- Insert sample reviews
INSERT OR IGNORE INTO reviews (id, booking_id, reviewer_id, artist_id, rating, comment) VALUES
('rev_1', 'book_1', 'user_6', 'artist_2', 5, 'Amazing energy! Had the whole crowd dancing. Will definitely book again.'),
('rev_2', 'book_3', 'user_6', 'artist_5', 4, 'Professional and creative. The styling made our event.');
