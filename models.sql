-- ✅ USER & AUTH MODULE

-- Users
New Files
CREATE TABLE users (
    id UUID PRIMARY KEY,  -- Unique identifier for each user
    first_name TEXT,  -- User's first name (e.g., "John")
    last_name TEXT,  -- User's last name (e.g., "Doe")
    email TEXT UNIQUE,  -- Unique email for authentication (e.g., "john@example.com")
    phone_number TEXT,  -- User's contact number (e.g., "+1234567890")
    status TEXT CHECK (status IN ('active', 'suspended')),  -- Account state
    verification_status BOOLEAN,  -- Status KYC verified
    subscription_type TEXT CHECK (subscription_type IN ('free', 'pro')),
    profile_picture_url TEXT,  -- Avatar/profile image
    is_email_verified BOOLEAN DEFAULT FALSE,  -- Email verification flag
    is_phone_verified BOOLEAN DEFAULT FALSE,  -- Phone verification flag
    account_type TEXT CHECK (account_type IN ('Handyman', 'Company')),  -- Account type  Need to be specified based on features 
    password_hash TEXT,  -- Hashed password for security
    password_reset_token TEXT,  -- Token for password reset 
    password_reset_expires TIMESTAMP,  -- Expiry for reset token
    two_factor_enabled BOOLEAN DEFAULT FALSE,  -- Two-factor authentication
    last_login TIMESTAMP,  -- Most recent login
    login_attempts INT DEFAULT 0,
    last_failed_login TIMESTAMP,
    last_failed_login_ip TEXT,  -- IP address of the last failed login
    last_successful_login_ip TEXT,  -- IP address of the last successful login
    created_at TIMESTAMP,  -- Account creation time
    updated_at TIMESTAMP  -- Last update
);

CREATE TABLE roles (
    role_id SERIAL PRIMARY KEY,
    role_name TEXT UNIQUE NOT NULL  -- e.g., 'customer', 'professional', 'admin'
);

CREATE TABLE user_roles (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role_id INT REFERENCES roles(role_id) ON DELETE CASCADE,
    assigned_at TIMESTAMP DEFAULT now(),
    UNIQUE (user_id, role_id)
);

CREATE TABLE professional_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    business_name TEXT,
    license_number TEXT,
    experience_years INT,
    website TEXT
);

-- ✅ SERVICE PROVIDER MODULE

CREATE TABLE service_providers (
    provider_id UUID PRIMARY KEY,  -- Unique provider ID
    user_id UUID REFERENCES users(id),  -- Link to user account
    business_roles TEXT,  -- Services they offer (e.g., "Cleaner") 
    introduction TEXT,  -- Bio or about (e.g., "35+ years of experience...")
    years_in_business INT,  -- Business experience
    employees_count INT,  -- Size of business team
    background_check_status TEXT CHECK (background_check_status IN ('pending', 'approved')), -- Background check status
    guarantee BOOLEAN,  -- Offers service guarantee? --Pro
    visibility_level TEXT CHECK (visibility_level IN ('standard', 'featured')) DEFAULT 'standard',
    is_online_now BOOLEAN,  -- Real-time availability
    last_seen_at TIMESTAMP,  -- Presence tracking
    last_active_at TIMESTAMP,  -- Last activity 
    total_hires INT DEFAULT 0,  -- How many times hired
    last_hire_date TIMESTAMP,  -- Most recent hire date
    contact_method TEXT CHECK (contact_method IN ('phone', 'email', 'whatsapp')),
    contact_value TEXT,  -- Actual email/number
    preferred_contact BOOLEAN DEFAULT FALSE,  -- If it's the main contact method
    provider_rating_avg DECIMAL(2,1),  -- Average review rating
    total_reviews INT DEFAULT 0,  -- Number of reviews
    credits_balance INT DEFAULT 0,  -- Credit balance for pro features
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE services_offered (
    id SERIAL PRIMARY KEY,
    provider_id UUID REFERENCES service_providers(provider_id) ON DELETE CASCADE,
    location_id INT REFERENCES locations(id) ON DELETE SET NULL, -- Service can be location-specific or NULL
    subservice_id INT REFERENCES subservices(subservice_id),
    custom_title VARCHAR(100),
    price_min NUMERIC,
    price_max NUMERIC,
    pricing_type TEXT NOT NULL, -- Pricing unit
    time_line TEXT,
    description TEXT,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    UNIQUE (provider_id, subservice_id, location_id)
);

CREATE TABLE provider_portfolios (
    id SERIAL PRIMARY KEY,
    service_offered_id INT REFERENCES services_offered(id) ON DELETE CASCADE,
    media_url TEXT,
    media_type TEXT CHECK (media_type IN ('photo')),
    uploaded_at TIMESTAMP DEFAULT now()
);

-- Table: provider_licenses
-- Stores official licenses or certifications held by service providers.
CREATE TABLE provider_licenses (
    license_id SERIAL PRIMARY KEY,
    provider_id UUID NOT NULL REFERENCES service_providers(provider_id) ON DELETE CASCADE,
    name TEXT NOT NULL,         -- Name of the license/certificate
    license_number TEXT NOT NULL, -- Official license/certificate number
    issue_date DATE,
    expiry_date DATE,
    issuing_authority TEXT,       -- Organization that issued the license
    license_type TEXT NOT NULL CHECK (license_type IN ('business', 'personal')),
    document_url TEXT,            -- Direct link to scanned license/certificate
    status TEXT CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
    verified_by_platform BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);
-- Table: provider_business_hours
-- Defines weekly business hours and availability for each provider, supporting multiple shifts and timezones.
CREATE TABLE provider_business_hours (
    id SERIAL PRIMARY KEY,
    provider_id UUID NOT NULL REFERENCES service_providers(provider_id) ON DELETE CASCADE,
    day_of_week SMALLINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Sunday, 6=Saturday
    open_time TIME,
    close_time TIME,
    availability_status TEXT, -- Indicates if the provider is available during this time
    is_closed BOOLEAN DEFAULT FALSE,          -- Marks day/shift as closed
    timezone TEXT NOT NULL,                   -- IANA timezone string
    notes TEXT,                              -- Special notes (e.g., "Closed on holidays")
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    UNIQUE (provider_id, day_of_week, shift_number)
);

-- Definition: Each row represents a provider's availability for a specific day/shift, supporting complex schedules, timezones, and future changes.

-- Table: provider_profile_media
-- Stores media (e.g., photos) for a provider's general profile, not tied to a specific service


-- Track all credit transactions (purchases, deductions, etc.)
CREATE TABLE credit_transactions (
    id SERIAL PRIMARY KEY,
    provider_id UUID REFERENCES service_providers(provider_id) ON DELETE CASCADE,
    amount INT NOT NULL, -- Negative for deduction, positive for addition
    transaction_type TEXT CHECK (transaction_type IN ('deduction', 'addition', 'purchase', 'refund', 'admin_adjustment')),
    reason TEXT, -- e.g., 'Unlock Profile Visibility', 'Purchased credits'
    related_feature TEXT, -- e.g., 'profile_visibility', 'search_ranking'
    created_at TIMESTAMP DEFAULT now()
);

-- Track which pro features a provider has unlocked
CREATE TABLE provider_pro_features (
    id SERIAL PRIMARY KEY,
    provider_id UUID REFERENCES service_providers(provider_id) ON DELETE CASCADE,
    feature_name TEXT NOT NULL, -- e.g., 'search_ranking', 'profile_visibility', etc.
    unlocked_at TIMESTAMP DEFAULT now(),
    expires_at TIMESTAMP, -- Optional: for time-limited features
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE (provider_id, feature_name)
);

-- (Optional) Define available credit packages for purchase
CREATE TABLE credit_packages (
    id SERIAL PRIMARY KEY,
    name TEXT,
    credits INT NOT NULL,
    price NUMERIC NOT NULL
);
-- ✅ CARD DETAILS (store user card info, only last 4 digits)
CREATE TABLE card_details (
    card_id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    card_number TEXT, -- Store only last 4 digits for security
    card_type TEXT,   -- e.g., 'Visa', 'MasterCard'
    expiry_month INT,
    expiry_year INT,
    cardholder_name TEXT,
    billing_address TEXT,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

-- ✅ CREDIT PURCHASES (track provider credit purchases via card)
CREATE TABLE credit_purchases (
    purchase_id SERIAL PRIMARY KEY,
    provider_id UUID REFERENCES service_providers(provider_id) ON DELETE CASCADE,
    card_id INT REFERENCES card_details(card_id),
    credits_purchased INT NOT NULL,
    amount_paid NUMERIC NOT NULL,
    purchase_time TIMESTAMP DEFAULT now(),
    status TEXT CHECK (status IN ('pending', 'completed', 'failed')) DEFAULT 'pending'
);

-- ✅ DYNAMIC FORMS

CREATE TABLE service_request_forms (
    form_id SERIAL PRIMARY KEY,
    subservice_id INT REFERENCES subservices(subservice_id),
    provider_is INT REFERENCES service_providers(provider_id),
    form_type TEXT CHECK (form_type IN ('text', 'checkbox', 'date', 'select')),
    question TEXT,
    options JSONB,
    form_group TEXT,
    step INT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE service_request_answers (
    answer_id SERIAL PRIMARY KEY,
    form_id INT REFERENCES service_request_forms(form_id),
    user_id UUID REFERENCES users(id),
    answer_text TEXT,   
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
-- details  // 

-- ✅ SERVICES, CATEGORIES & TAGGING

CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name TEXT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE services (
    service_id SERIAL PRIMARY KEY,
    service_name TEXT,
    category_id INT REFERENCES categories(category_id),
    description TEXT,
    profile text,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE subservices (
    subservice_id SERIAL PRIMARY KEY,
    subservice_name TEXT,
    service_id INT REFERENCES services(service_id),
    description TEXT,
    tags TEXT[],
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- ✅ REQUESTS, PROPOSALS, REVIEWS

CREATE TABLE requests (
    request_id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    subservice_id INT REFERENCES subservices(subservice_id),
    location_city TEXT,
    location_state TEXT,
    location_zip TEXT,
    description TEXT,
    budget TEXT,
    deadline DATE,
    preferred_start_date DATE,
    preferred_time TIME,
    is_urgent BOOLEAN,
    status TEXT CHECK (status IN ('pending', 'accepted', 'completed', 'cancelled')),
    request_date TIMESTAMP,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE proposals (
    proposal_id SERIAL PRIMARY KEY,
    request_id INT REFERENCES requests(request_id),
    provider_id UUID REFERENCES service_providers(provider_id),
    price TEXT,
    estimated_duration TEXT,
    response_message TEXT,
    status TEXT CHECK (status IN ('pending', 'accepted', 'rejected')),
    match_score DECIMAL(5,2),  -- ML/AI-driven matching
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE reviews (
    review_id SERIAL PRIMARY KEY,
    request_id INT REFERENCES requests(request_id),
    provider_id UUID REFERENCES service_providers(provider_id),
    reviewer_id UUID REFERENCES users(id), -- client
    rating INT CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    media_attachment_url TEXT,
    created_at TIMESTAMP DEFAULT now()
);

-- ✅ SUPPORT / CHAT / NOTIFICATIONS
CREATE TABLE support_tickets (
    ticket_id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    subject TEXT,
    message TEXT,
    channel TEXT CHECK (channel IN ('email', 'live_chat')) DEFAULT 'email', 
    status TEXT CHECK (status IN ('open', 'closed')),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE messages (
    message_id SERIAL PRIMARY KEY,
    ticket_id INT REFERENCES support_tickets(ticket_id),
    sender_id UUID REFERENCES users(id),
    message_text TEXT,
    sent_at TIMESTAMP
);

CREATE TABLE notifications (
    notification_id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    title TEXT,
    message TEXT,
    link_url TEXT,
    read_status BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP
);

-- Table: conversations
-- Stores a conversation between two users (customer and provider)
CREATE TABLE conversations (
    conversation_id SERIAL PRIMARY KEY,
    user1_id UUID REFERENCES users(id), -- One participant (customer or provider)
    user2_id UUID REFERENCES users(id), -- The other participant
    started_at TIMESTAMP DEFAULT now(),
    last_message_at TIMESTAMP DEFAULT now(),
    is_email BOOLEAN DEFAULT FALSE, -- TRUE if this is an email-based conversation
    UNIQUE (user1_id, user2_id, is_email)
);

-- Table: conversation_messages
-- Stores messages exchanged in a conversation (live chat or email)
CREATE TABLE conversation_messages (
    message_id SERIAL PRIMARY KEY,
    conversation_id INT REFERENCES conversations(conversation_id) ON DELETE CASCADE,
    sender_id UUID REFERENCES users(id),
    recipient_id UUID REFERENCES users(id),
    message_text TEXT,
    sent_at TIMESTAMP DEFAULT now(),
    is_read BOOLEAN DEFAULT FALSE,
    is_email BOOLEAN DEFAULT FALSE, -- TRUE if this message was sent by email
    email_subject TEXT, -- Optional, for email messages
    email_status TEXT CHECK (email_status IN ('pending', 'sent', 'failed')),
    -- You can add attachments, etc. as needed
    UNIQUE (conversation_id, message_id)
);

-- ✅ TRUST & SAFETY
CREATE TABLE incident_reports (
    id SERIAL PRIMARY KEY,
    reporter_id UUID REFERENCES users(id),
    reported_user_id UUID REFERENCES users(id),
    reason TEXT,
    notes TEXT,
    strike_count INT DEFAULT 0,
    suspended BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP
);

CREATE TABLE saved_items (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    saved_type TEXT CHECK (saved_type IN ('job', 'provider')),
    reference_id INT, -- job_id or provider_id
    created_at TIMESTAMP DEFAULT now()
);


-- =============================================
-- JOBS MODULE DATABASE MODELS
-- =============================================

-- ✅  JOB PROFILES
-- Represents individual or professional profiles created by service providers to attract job opportunities

CREATE TABLE job_profiles (
    profile_id SERIAL PRIMARY KEY,
    provider_id UUID REFERENCES service_providers(provider_id),
    profile_type TEXT CHECK (profile_type IN ('freelancer', 'professional')) NOT NULL,
    business_name TEXT,                         -- Required for professional profiles
    headline TEXT NOT NULL,                     -- Summary title for the profile
    summary TEXT,                               -- Detailed overview
    expected_rate TEXT,                         -- e.g., "$50/hr" or "$1000/project"
    availability TEXT,                          -- e.g., "Full-time", "Weekends Only"
    skills TEXT[],                              -- e.g., ['Electrician', 'Plumbing']
    location_city TEXT,
    background_check_status TEXT CHECK (background_check_status IN ('pending', 'approved')), -- Need to be specified based on features
    location_state TEXT,
    remote_allowed BOOLEAN DEFAULT FALSE,
    team_size INT,                              -- Required for professionals
    years_experience INT,
    website_url TEXT,                           -- Optional business or portfolio website
    resume_url TEXT,                            -- Optional resume or CV link
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

-- ✅ 2. JOB PROFILE REFERENCES
-- References from past clients, colleagues, or employers

CREATE TABLE job_profile_references (
    reference_id SERIAL PRIMARY KEY,
    profile_id INT REFERENCES job_profiles(profile_id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    relation TEXT,                            -- e.g., "Supervisor", "Client"
    contact_email TEXT,
    contact_phone TEXT,
    reference_letter_url TEXT,                -- Optional uploaded file
    verified BOOLEAN DEFAULT FALSE,   -- Pro
    created_at TIMESTAMP DEFAULT now()
);

-- ✅ 3. JOB PROFILE EXPERIENCE
-- Prior work experience entries for a provider profile
CREATE TABLE job_profile_experience (
    experience_id SERIAL PRIMARY KEY,
    profile_id INT REFERENCES job_profiles(profile_id) ON DELETE CASCADE,
    position_title TEXT NOT NULL,
    company_name TEXT NOT NULL,
    location TEXT,
    start_date DATE NOT NULL,
    end_date DATE,
    is_current BOOLEAN DEFAULT FALSE,
    description TEXT,
    created_at TIMESTAMP DEFAULT now()
);

-- ✅ 4. JOB PROFILE EDUCATION
-- Educational background for service providers

CREATE TABLE job_profile_education (
    education_id SERIAL PRIMARY KEY,
    profile_id INT REFERENCES job_profiles(profile_id) ON DELETE CASCADE,
    institution_name TEXT NOT NULL,
    degree TEXT,
    field_of_study TEXT,
    start_year INT,
    end_year INT,
    certification_url TEXT,
    created_at TIMESTAMP DEFAULT now()
);

-- ✅ 5. JOB ANNOUNCEMENTS
-- Clients post job listings to attract service providers
CREATE TABLE job_announcements (
    job_id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    category_id INT REFERENCES categories(category_id),
    location_city TEXT,
    location_state TEXT,
    location_zip TEXT,
    budget TEXT,
    preferred_start_date DATE,
    deadline DATE,
    status TEXT CHECK (status IN ('open', 'closed', 'cancelled')) DEFAULT 'open',
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

-- ✅ 6. JOB APPLICATIONS
-- Service providers apply to job announcements
CREATE TABLE job_applications (
    application_id SERIAL PRIMARY KEY,
    job_id INT REFERENCES job_announcements(job_id) ON DELETE CASCADE,
    provider_id UUID REFERENCES service_providers(provider_id),
    cover_letter TEXT,
    expected_rate TEXT,
    status TEXT CHECK (status IN ('pending', 'accepted', 'rejected', 'withdrawn')) DEFAULT 'pending',
    submitted_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

-- Table: job_announcement_search_log
-- Logs each job announcement search and the top 10 matched job seekers
CREATE TABLE job_announcement_search_log (
    id SERIAL PRIMARY KEY,
    job_id INT REFERENCES job_announcements(job_id) ON DELETE CASCADE,
    search_keywords TEXT,
    search_time TIMESTAMP DEFAULT now(),
    top_job_seeker_ids UUID[], -- Array of top 10 user_ids (job seekers)
    created_at TIMESTAMP DEFAULT now()
);

-- Table: job_announcement_offers
-- Stores offers sent to top 10 matched job seekers
CREATE TABLE job_announcement_offers (
    offer_id SERIAL PRIMARY KEY,
    search_log_id INT REFERENCES job_announcement_search_log(id) ON DELETE CASCADE,
    job_seeker_id UUID REFERENCES users(id),
    job_id INT REFERENCES job_announcements(job_id),
    status TEXT CHECK (status IN ('sent', 'opened', 'accepted', 'rejected')) DEFAULT 'sent',
    opened_at TIMESTAMP,
    accepted_at TIMESTAMP,
    rejected_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    UNIQUE (search_log_id, job_seeker_id)
);

-- Table: professional_search_log
-- Logs each customer search and the top 5 matched providers
CREATE TABLE professional_search_log (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id), -- Customer who searched
    subservice_id INT REFERENCES subservices(subservice_id),
    search_keywords TEXT,
    search_time TIMESTAMP DEFAULT now(),
    top_provider_ids UUID[], -- Array of top 5 provider_ids
    created_at TIMESTAMP DEFAULT now()
);

-- Table: professional_offers
-- Stores offers sent to top 5 matched providers
CREATE TABLE professional_offers (
    offer_id SERIAL PRIMARY KEY,
    search_log_id INT REFERENCES professional_search_log(id) ON DELETE CASCADE,
    provider_id UUID REFERENCES service_providers(provider_id),
    request_id INT REFERENCES requests(request_id),
    status TEXT CHECK (status IN ('sent', 'opened', 'accepted', 'rejected')) DEFAULT 'sent',
    opened_at TIMESTAMP,
    accepted_at TIMESTAMP,
    rejected_at TIMESTAMP,
    credits_deducted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    UNIQUE (search_log_id, provider_id)
);

-- Master locations table for all entities
CREATE TABLE locations (
    id SERIAL PRIMARY KEY,
    address_line1 TEXT,
    address_line2 TEXT,
    city TEXT,
    state TEXT,
    zip TEXT,
    timezone TEXT,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

-- User to location join table
CREATE TABLE user_locations (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    location_id INT REFERENCES locations(id) ON DELETE CASCADE,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

-- Provider to location join table
CREATE TABLE provider_locations (
    id SERIAL PRIMARY KEY,
    provider_id UUID REFERENCES service_providers(provider_id) ON DELETE CASCADE,
    location_id INT REFERENCES locations(id) ON DELETE CASCADE,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

-- Request to location join table
CREATE TABLE request_locations (
    id SERIAL PRIMARY KEY,
    request_id INT REFERENCES requests(request_id) ON DELETE CASCADE,
    location_id INT REFERENCES locations(id) ON DELETE CASCADE
);

-- Job announcement to location join table
CREATE TABLE job_announcement_locations (
    id SERIAL PRIMARY KEY,
    job_id INT REFERENCES job_announcements(job_id) ON DELETE CASCADE,
    location_id INT REFERENCES locations(id) ON DELETE CASCADE
);

-- Table: call_requests
-- Stores call requests from users to providers
CREATE TABLE call_requests (
    id SERIAL PRIMARY KEY,
    requester_id UUID REFERENCES users(id) NOT NULL, -- User who requests the call
    provider_id UUID REFERENCES service_providers(provider_id) NOT NULL, -- Provider to call
    requested_at TIMESTAMP DEFAULT now(),
    status TEXT CHECK (status IN ('pending', 'completed', 'cancelled')) DEFAULT 'pending',
    scheduled_time TIMESTAMP, -- Optional: scheduled call time
    notes TEXT, -- Optional: extra info from requester
    UNIQUE (requester_id, provider_id, requested_at)
);

2. Key Relationships
User & Auth
users ← user_rules (M:N via join table)
users ← professional_profiles (1:1)
users ← user_feature_flags (1:M)
users ← user_subscriptions (1:M)
users ← card_details (1:M)
Service Providers
users ← service_providers (1:M)
service_providers ← provider_licenses (1:M)
service_providers ← provider_business_hours (1:M)
service_providers ← services_offered (1:M)
service_providers ← job_profiles (1:1)
service_providers ← proposals (1:M)
service_providers ← reviews (1:M)
service_providers ← match_history (1:M)
services_offered ← provider_portfolios (1:M)
Services & Categories
categories ← services (1:M)
services ← subservices (1:M)
subservices ← service_request_forms (1:M)
subservices ← services_offered (1:M)
Requests & Proposals
users ← requests (1:M)
requests ← proposals (1:M)
requests ← reviews (1:M)
requests ← match_history (1:M)
Jobs Module
service_providers ← job_profiles (1:1)
job_profiles ← job_profile_references (1:M)
job_profiles ← job_profile_experience (1:M)
job_profiles ← job_profile_education (1:M)
users ← job_announcements (1:M)
categories ← job_announcements (1:M)
job_announcements ← job_applications (1:M)
service_providers ← job_applications (1:M)


link of the database: https://dbdiagram.io/d/651b0f2c4a3d1e001f7a5b8c
