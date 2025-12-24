-- Seed data for Gearsh MVP

-- Insert sample users
INSERT OR IGNORE INTO users (id, email, password_hash, user_type, first_name, last_name, display_name, profile_picture_url, location, country, bio, is_verified) VALUES
('user_1', 'djmaphorisa@gearsh.com', '$2a$10$dummy_hash', 'artist', 'Themba', 'Sonnyboy', 'DJ Maphorisa', 'https://example.com/maphorisa.jpg', 'Johannesburg', 'South Africa', 'Award-winning DJ and producer known for Amapiano hits', 1),
('user_2', 'kabza@gearsh.com', '$2a$10$dummy_hash', 'artist', 'Kabelo', 'Motha', 'Kabza De Small', 'https://example.com/kabza.jpg', 'Pretoria', 'South Africa', 'The Piano King - Amapiano pioneer', 1),
('user_3', 'cassper@gearsh.com', '$2a$10$dummy_hash', 'artist', 'Refiloe', 'Phoolo', 'Cassper Nyovest', 'https://example.com/cassper.jpg', 'Johannesburg', 'South Africa', 'Multi-platinum rapper and entrepreneur', 1),
('user_4', 'kendrick@gearsh.com', '$2a$10$dummy_hash', 'artist', 'Kendrick', 'Lamar', 'Kendrick Lamar', 'https://example.com/kendrick.jpg', 'Compton', 'USA', 'Pulitzer Prize-winning rapper', 1),
('user_5', 'nota@gearsh.com', '$2a$10$dummy_hash', 'artist', 'Nhlamulo', 'Baloyi', 'Nota Baloyi', 'https://example.com/nota.jpg', 'Johannesburg', 'South Africa', 'Music industry executive and host', 1),
('user_6', 'client1@example.com', '$2a$10$dummy_hash', 'client', 'John', 'Doe', NULL, NULL, 'Cape Town', 'South Africa', NULL, 0),
('user_7', 'client2@example.com', '$2a$10$dummy_hash', 'client', 'Jane', 'Smith', NULL, NULL, 'Durban', 'South Africa', NULL, 0);

-- Insert artist profiles
INSERT OR IGNORE INTO artist_profiles (id, user_id, category, genre, base_rate, hourly_rate, years_experience, skills, is_trending, avg_rating, total_reviews) VALUES
('artist_1', 'user_1', 'DJ', 'Amapiano', 700, 150, 15, '["Mixing", "Production", "Live Performance"]', 1, 4.7, 156),
('artist_2', 'user_2', 'DJ', 'Amapiano', 800, 180, 10, '["Piano", "Mixing", "Production"]', 1, 4.9, 203),
('artist_3', 'user_3', 'Hip Hop', 'Rap', 550, 120, 12, '["Rapping", "Songwriting", "Performance"]', 0, 4.8, 178),
('artist_4', 'user_4', 'Rap', 'Hip Hop', 1500, 300, 18, '["Rapping", "Songwriting", "Production"]', 1, 5.0, 320),
('artist_5', 'user_5', 'Host', 'MC', 350, 80, 8, '["Hosting", "Public Speaking", "Event Management"]', 0, 4.5, 89);

-- Insert services
INSERT OR IGNORE INTO services (id, artist_id, name, description, price, duration_hours) VALUES
('svc_1', 'artist_1', 'Club Set', '2-hour DJ set for clubs and lounges', 1400, 2),
('svc_2', 'artist_1', 'Private Event', '4-hour set for private events', 2800, 4),
('svc_3', 'artist_2', 'Festival Set', 'Main stage festival performance', 5000, 2),
('svc_4', 'artist_2', 'Studio Session', 'Production collaboration session', 3000, 4),
('svc_5', 'artist_3', 'Concert Performance', 'Full concert performance', 8000, 2),
('svc_6', 'artist_4', 'Private Show', 'Exclusive private performance', 25000, 2),
('svc_7', 'artist_5', 'Event Hosting', 'Professional MC services', 2500, 4);

-- Insert sample bookings
INSERT OR IGNORE INTO bookings (id, client_id, artist_id, service_id, event_date, event_time, event_location, event_type, duration_hours, total_price, status) VALUES
('book_1', 'user_6', 'artist_1', 'svc_1', '2025-01-15', '20:00', 'Taboo Club, Johannesburg', 'Club Night', 2, 1400, 'confirmed'),
('book_2', 'user_7', 'artist_2', 'svc_3', '2025-02-20', '18:00', 'FNB Stadium', 'Festival', 2, 5000, 'pending'),
('book_3', 'user_6', 'artist_5', 'svc_7', '2025-01-25', '14:00', 'Sandton Convention Centre', 'Corporate Event', 4, 2500, 'confirmed');

-- Insert sample reviews
INSERT OR IGNORE INTO reviews (id, booking_id, reviewer_id, artist_id, rating, comment) VALUES
('rev_1', 'book_1', 'user_6', 'artist_1', 5, 'Amazing energy! Had the whole crowd dancing. Will definitely book again.'),
('rev_2', 'book_3', 'user_6', 'artist_5', 4, 'Professional and engaging. Great MC for our corporate event.');

