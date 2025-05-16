-- ✅ USER & AUTH MODULE

-- Users
CREATE TABLE users (
    id UUID PRIMARY KEY,  -- Unique identifier for each user
    first_name TEXT,  -- User's first name (e.g., "John")
    last_name TEXT,  -- User's last name (e.g., "Doe")
    email TEXT UNIQUE,  -- Unique email for authentication (e.g., "john@example.com")
    phone_number TEXT,  -- User's contact number (e.g., "+1234567890")
    role TEXT CHECK (role IN ('customer', 'Professional', 'admin')),  -- Main role type
    timezone TEXT,  -- Timezone of the user (e.g., "America/New_York")
    location_city TEXT,  -- City (e.g., "Los Angeles")
    location_state TEXT,  -- State (e.g., "CA")
    location_zip TEXT,  -- Zip code (e.g., "90001")
    status TEXT CHECK (status IN ('active', 'suspended')),  -- Account state
    verification_status BOOLEAN,  -- Status KYC verified
    subscription_type TEXT CHECK (subscription_type IN ('free', 'pro')),
    profile_picture_url TEXT,  -- Avatar/profile image
    is_email_verified BOOLEAN DEFAULT FALSE,  -- Email verification flag
    account_type TEXT CHECK (account_type IN ('Handyman', 'Company')),  -- Account type  Need to be specified based on features 
    password_hash TEXT,  -- Hashed password for security
    password_reset_token TEXT,  -- Token for password reset 
    password_reset_expires TIMESTAMP,  -- Expiry for reset token
    two_factor_enabled BOOLEAN DEFAULT FALSE,  -- Two-factor authentication
    last_login TIMESTAMP,  -- Most recent login
    created_at TIMESTAMP,  -- Account creation time
    updated_at TIMESTAMP  -- Last update
);

-- ✅ SERVICE PROVIDER MODULE

CREATE TABLE service_providers (
    provider_id UUID PRIMARY KEY,  -- Unique provider ID
    user_id UUID REFERENCES users(id),  -- Link to user account
    business_roles TEXT,  -- Services they offer (e.g., "Cleaner") 
    introduction TEXT,  -- Bio or about (e.g., "35+ years of experience...")
    years_in_business INT,  -- Business experience
    employees_count INT,  -- Size of business team
    background_check_status TEXT CHECK (background_check_status IN ('pending', 'approved')), -- Need to be specified based on features
    guarantee BOOLEAN,  -- Offers service guarantee? --Pro
    visibility_level TEXT CHECK (visibility_level IN ('standard', 'featured')) DEFAULT 'standard'
    portfolio_photos TEXT[],  -- Array of images -- Need another table
    is_online_now BOOLEAN,  -- Real-time availability
    last_seen_at TIMESTAMP,  -- Presence tracking
    last_active_at TIMESTAMP,  -- Last activity 
    total_hires INT DEFAULT 0,  -- How many times hired
    last_hire_date TIMESTAMP,  -- Most recent hire date
    contact TEXT CHECK (method IN ('phone', 'email', 'whatsapp')),
    contact_value TEXT,  -- Actual email/number
    preferred check  -- If it's the main contact method
    provider_rating_avg DECIMAL(2,1),  -- Average review rating for example If a provider has three reviews with ratings 5, 4, and 5, then provider_rating_avg = (5+4+5)/3 = 4.7.
    total_reviews INT DEFAULT 0,  -- Number of reviews
    created_at TIMESTAMP,
    updated_at TIMESTAMP
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
    answer_text TEXT,   // 
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
-- details  // 


CREATE TABLE services_offered (
    id SERIAL PRIMARY KEY,
    provider_id UUID REFERENCES service_providers(provider_id) ON DELETE CASCADE,
    subservice_id INT REFERENCES subservices(subservice_id),
    custom_title VARCHAR(100),
    price_min NUMERIC,
    price_max NUMERIC,
    cost_per_hour NUMERIC,
    cost_per_day NUMERIC,
    time_line TEXT,
    description TEXT,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    UNIQUE (provider_id, subservice_id)
);

CREATE TABLE provider_service_media (
    id SERIAL PRIMARY KEY,
    service_offered_id INT REFERENCES provider_services_offered(id) ON DELETE CASCADE,
    media_url TEXT,
    media_type TEXT CHECK (media_type IN ('photo')),
    uploaded_at TIMESTAMP DEFAULT now()
);



-- Table: provider_licenses
-- Stores official licenses or certifications held by service providers.
CREATE TABLE provider_licenses (
    license_id SERIAL PRIMARY KEY,
    provider_id UUID NOT NULL REFERENCES service_providers(provider_id) ON DELETE CASCADE,
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
    shift_number SMALLINT NOT NULL DEFAULT 1, -- Allows multiple shifts per day
    open_time TIME,
    close_time TIME,
    availability_status TEXT CHECK calandar-- Indicates if the provider is available during this time
    is_closed BOOLEAN DEFAULT FALSE,          -- Marks day/shift as closed
    timezone TEXT NOT NULL,                   -- IANA timezone string
    notes TEXT,                              -- Special notes (e.g., "Closed on holidays")
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    UNIQUE (provider_id, day_of_week, shift_number)
);
-- Definition: Each row represents a provider's availability for a specific day/shift, supporting complex schedules, timezones, and future changes.


-- ✅ SUBSCRIPTIONS & PAYMENTS

CREATE TABLE subscription_plans (
    plan_id SERIAL PRIMARY KEY,
    plan_name TEXT,  -- "Pro Monthly"
    price NUMERIC,
    features JSONB,  -- Feature list
    duration_days INT,  -- Subscription length
    trial_ends_at DATE,  -- Trial end
    grace_period_days INT,  -- Buffer after expiry
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE user_subscriptions (
    subscription_id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    plan_id INT REFERENCES subscription_plans(plan_id),
    start_date DATE,
    end_date DATE,
    status TEXT CHECK (status IN ('active', 'cancelled', 'expired')),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE card_details (
    card_id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    cardholder_name TEXT,
    card_token TEXT,
    card_last_four TEXT,
    card_type TEXT,
    expiry_date DATE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);


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
    channel TEXT CHECK (channel IN ('email', 'live_chat')) DEFAULT 'email'
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




CREATE TABLE match_history (
    id SERIAL PRIMARY KEY,
    provider_id UUID REFERENCES service_providers(provider_id),
    request_id INT REFERENCES requests(request_id),
    score DECIMAL(5,2),
    calculated_at TIMESTAMP DEFAULT now()
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
    verified BOOLEAN DEFAULT FALSE,

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

-- ✅ 7. JOB SEARCH LOG
-- Tracks search behavior for personalization/analytics

CREATE TABLE job_search_log (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    keywords TEXT,
    filters JSONB,
    timestamp TIMESTAMP DEFAULT now()
);
-- ✅ RELATIONSHIPS SUMMARY (Job Module)

-- service_providers.provider_id → job_profiles.provider_id (1:1)
-- job_profiles.profile_id → job_profile_references.profile_id (1:M)
-- job_profiles.profile_id → job_profile_experience.profile_id (1:M)
-- job_profiles.profile_id → job_profile_education.profile_id (1:M)

-- users.id → job_announcements.user_id (1:M)
-- categories.category_id → job_announcements.category_id (M:1)

-- job_announcements.job_id → job_applications.job_id (1:M)
-- service_providers.provider_id → job_applications.provider_id (1:M)

-- users.id → job_search_log.user_id (1:M)
