-- Community Tab Database Schema for Supabase
-- Bible v1 - Full Build Implementation
-- Generated: 2026-01-11

-- ============================================
-- ENUMS
-- ============================================

-- Verification types
CREATE TYPE verification_type AS ENUM ('church', 'leader', 'notable');

-- Post types
CREATE TYPE post_type AS ENUM ('reflection', 'question', 'prayer', 'testimony', 'image', 'verse_card');

-- Reflection types
CREATE TYPE reflection_type AS ENUM ('insight', 'question', 'prayer', 'testimony', 'teaching');

-- Post tones
CREATE TYPE post_tone AS ENUM ('encouragement', 'lament', 'gratitude', 'confession', 'hope');

-- Visibility levels
CREATE TYPE visibility_level AS ENUM ('public', 'followers', 'group');

-- Reaction types
CREATE TYPE reaction_type AS ENUM ('amen', 'prayed', 'love', 'helpful', 'curious', 'hug');

-- Follow states
CREATE TYPE follow_state AS ENUM ('active', 'pending', 'blocked');

-- Group types
CREATE TYPE group_type AS ENUM ('topic', 'reading_plan', 'church', 'study');

-- Group privacy levels
CREATE TYPE group_privacy AS ENUM ('public', 'private', 'hidden');

-- Group roles
CREATE TYPE group_role AS ENUM ('owner', 'moderator', 'member');

-- Event types
CREATE TYPE event_type AS ENUM ('study', 'prayer', 'live_room', 'meetup');

-- Conversation types
CREATE TYPE conversation_type AS ENUM ('direct', 'group_chat');

-- Message request status
CREATE TYPE message_request_status AS ENUM ('pending', 'accepted', 'declined');

-- Live room types
CREATE TYPE live_room_type AS ENUM ('prayer', 'study', 'discussion', 'open');

-- Live room status
CREATE TYPE live_room_status AS ENUM ('scheduled', 'live', 'ended');

-- Room participant roles
CREATE TYPE room_role AS ENUM ('host', 'co_host', 'speaker', 'listener');

-- Prayer categories
CREATE TYPE prayer_category AS ENUM ('health', 'family', 'work', 'anxiety', 'finances', 'relationships', 'spiritual', 'other');

-- Prayer urgency
CREATE TYPE prayer_urgency AS ENUM ('urgent', 'normal');

-- Prayer update types
CREATE TYPE prayer_update_type AS ENUM ('update', 'answered', 'continued');

-- Trending item types
CREATE TYPE trending_type AS ENUM ('verse', 'topic', 'tag');

-- Report target types
CREATE TYPE report_target_type AS ENUM ('post', 'comment', 'user', 'group', 'room', 'message');

-- Report reasons
CREATE TYPE report_reason AS ENUM ('spam', 'harassment', 'hate', 'misinformation', 'self_harm', 'inappropriate', 'other');

-- Report status
CREATE TYPE report_status AS ENUM ('pending', 'reviewing', 'resolved', 'dismissed');

-- Mute types
CREATE TYPE mute_type AS ENUM ('user', 'group', 'topic');

-- Moderation actions
CREATE TYPE moderation_action_type AS ENUM ('warn', 'mute', 'ban', 'delete', 'restore');

-- Keyword filter actions
CREATE TYPE filter_action AS ENUM ('flag', 'block', 'require_review');

-- Keyword filter categories
CREATE TYPE filter_category AS ENUM ('spam', 'profanity', 'political', 'crisis');

-- Verification request status
CREATE TYPE verification_status AS ENUM ('pending', 'approved', 'rejected');

-- ============================================
-- CORE TABLES
-- ============================================

-- Community Profiles (extends auth.users)
CREATE TABLE community_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL,
    username TEXT UNIQUE,
    avatar_url TEXT,
    bio TEXT CHECK (char_length(bio) <= 500),
    testimony TEXT CHECK (char_length(testimony) <= 2000),
    favorite_verse_ref JSONB,
    preferred_translation TEXT DEFAULT 'KJV',
    denomination TEXT,
    church_name TEXT,
    location_city TEXT,
    location_lat DECIMAL(10, 8),
    location_lng DECIMAL(11, 8),
    is_verified BOOLEAN DEFAULT FALSE,
    verification_type verification_type,
    privacy_settings JSONB DEFAULT '{"profile_visible": true, "show_activity": true, "allow_messages": "requests"}'::jsonb,
    content_filters JSONB DEFAULT '{"hide_political": true, "scripture_only": false, "blocked_keywords": []}'::jsonb,
    follower_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    post_count INTEGER DEFAULT 0,
    prayer_count INTEGER DEFAULT 0,
    badges JSONB[] DEFAULT '{}',
    last_active_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Posts
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id UUID REFERENCES community_profiles(id) ON DELETE CASCADE,
    type post_type NOT NULL,
    content TEXT NOT NULL,
    verse_ref JSONB,
    reflection_type reflection_type,
    tone post_tone,
    tags TEXT[] DEFAULT '{}',
    media_urls TEXT[] DEFAULT '{}',
    verse_card_config JSONB,
    visibility visibility_level DEFAULT 'public',
    group_id UUID,
    is_anonymous BOOLEAN DEFAULT FALSE,
    allow_comments BOOLEAN DEFAULT TRUE,
    is_pinned BOOLEAN DEFAULT FALSE,
    engagement JSONB DEFAULT '{"amen": 0, "prayed": 0, "love": 0, "helpful": 0, "curious": 0, "hug": 0, "comments": 0, "shares": 0}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Comments (with threading support)
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    author_id UUID REFERENCES community_profiles(id) ON DELETE CASCADE,
    parent_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
    depth INTEGER DEFAULT 0,
    content TEXT NOT NULL,
    is_anonymous BOOLEAN DEFAULT FALSE,
    engagement JSONB DEFAULT '{"amen": 0, "prayed": 0, "love": 0, "helpful": 0, "curious": 0, "hug": 0}'::jsonb,
    is_best_answer BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Reactions
CREATE TABLE reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES community_profiles(id) ON DELETE CASCADE,
    target_type TEXT NOT NULL CHECK (target_type IN ('post', 'comment')),
    target_id UUID NOT NULL,
    reaction_type reaction_type NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, target_type, target_id, reaction_type)
);

-- Follows
CREATE TABLE follows (
    follower_id UUID NOT NULL REFERENCES community_profiles(id) ON DELETE CASCADE,
    followee_id UUID NOT NULL REFERENCES community_profiles(id) ON DELETE CASCADE,
    state follow_state DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (follower_id, followee_id)
);

-- Blocks
CREATE TABLE blocks (
    blocker_id UUID NOT NULL REFERENCES community_profiles(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES community_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (blocker_id, blocked_id)
);

-- ============================================
-- GROUPS TABLES
-- ============================================

-- Groups
CREATE TABLE groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    type group_type NOT NULL,
    privacy group_privacy DEFAULT 'public',
    avatar_url TEXT,
    cover_url TEXT,
    rules TEXT[] DEFAULT '{}',
    join_questions TEXT[] DEFAULT '{}',
    linked_reading_plan_id UUID,
    church_verification_status verification_status,
    member_count INTEGER DEFAULT 0,
    post_count INTEGER DEFAULT 0,
    weekly_prompt TEXT,
    settings JSONB DEFAULT '{}'::jsonb,
    created_by UUID REFERENCES community_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add foreign key for posts.group_id
ALTER TABLE posts ADD CONSTRAINT fk_posts_group FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE;

-- Group Members
CREATE TABLE group_members (
    group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES community_profiles(id) ON DELETE CASCADE,
    role group_role DEFAULT 'member',
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    join_answers JSONB,
    is_muted BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (group_id, user_id)
);

-- Group Events
CREATE TABLE group_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    event_type event_type NOT NULL,
    scheduled_at TIMESTAMPTZ NOT NULL,
    duration_minutes INTEGER DEFAULT 60,
    live_room_id UUID,
    created_by UUID REFERENCES community_profiles(id) ON DELETE SET NULL,
    attendee_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- MESSAGING TABLES
-- ============================================

-- Conversations
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type conversation_type DEFAULT 'direct',
    participant_ids UUID[] NOT NULL,
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    last_message_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Messages
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES community_profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    media_url TEXT,
    verse_ref JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- Message Requests
CREATE TABLE message_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_user_id UUID NOT NULL REFERENCES community_profiles(id) ON DELETE CASCADE,
    to_user_id UUID NOT NULL REFERENCES community_profiles(id) ON DELETE CASCADE,
    status message_request_status DEFAULT 'pending',
    initial_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    responded_at TIMESTAMPTZ
);

-- ============================================
-- LIVE TABLES
-- ============================================

-- Live Rooms
CREATE TABLE live_rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    type live_room_type DEFAULT 'open',
    host_id UUID NOT NULL REFERENCES community_profiles(id) ON DELETE CASCADE,
    co_host_ids UUID[] DEFAULT '{}',
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    status live_room_status DEFAULT 'scheduled',
    scheduled_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    max_participants INTEGER DEFAULT 100,
    is_video_enabled BOOLEAN DEFAULT FALSE,
    recording_url TEXT,
    participant_count INTEGER DEFAULT 0,
    settings JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add foreign key for group_events.live_room_id
ALTER TABLE group_events ADD CONSTRAINT fk_events_live_room FOREIGN KEY (live_room_id) REFERENCES live_rooms(id) ON DELETE SET NULL;

-- Room Participants
CREATE TABLE room_participants (
    room_id UUID NOT NULL REFERENCES live_rooms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES community_profiles(id) ON DELETE CASCADE,
    role room_role DEFAULT 'listener',
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    left_at TIMESTAMPTZ,
    is_muted BOOLEAN DEFAULT TRUE,
    has_raised_hand BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (room_id, user_id)
);

-- ============================================
-- PRAYER TABLES
-- ============================================

-- Prayer Requests (extends posts)
CREATE TABLE prayer_requests (
    post_id UUID PRIMARY KEY REFERENCES posts(id) ON DELETE CASCADE,
    category prayer_category DEFAULT 'other',
    urgency prayer_urgency DEFAULT 'normal',
    duration_days INTEGER DEFAULT 7,
    expires_at TIMESTAMPTZ,
    is_answered BOOLEAN DEFAULT FALSE,
    answered_at TIMESTAMPTZ,
    answered_note TEXT,
    prayer_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Prayer Circle Members
CREATE TABLE prayer_circle_members (
    prayer_post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES community_profiles(id) ON DELETE CASCADE,
    prayed_at TIMESTAMPTZ DEFAULT NOW(),
    has_reminder BOOLEAN DEFAULT FALSE,
    reminder_frequency TEXT CHECK (reminder_frequency IN ('daily', 'weekly')),
    PRIMARY KEY (prayer_post_id, user_id)
);

-- Prayer Updates
CREATE TABLE prayer_updates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prayer_post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES community_profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    update_type prayer_update_type DEFAULT 'update',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- DISCOVERY & INDEXING TABLES
-- ============================================

-- Verse Index (for Verse Hub)
CREATE TABLE verse_index (
    book TEXT NOT NULL,
    chapter INTEGER NOT NULL,
    verse INTEGER NOT NULL,
    translation_id TEXT NOT NULL,
    post_ids UUID[] DEFAULT '{}',
    post_count INTEGER DEFAULT 0,
    last_activity_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (book, chapter, verse, translation_id)
);

-- Trending Cache
CREATE TABLE trending_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type trending_type NOT NULL,
    identifier TEXT NOT NULL,
    score FLOAT DEFAULT 0,
    post_count_24h INTEGER DEFAULT 0,
    engagement_24h INTEGER DEFAULT 0,
    computed_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Reading Patterns
CREATE TABLE user_reading_patterns (
    user_id UUID PRIMARY KEY REFERENCES community_profiles(id) ON DELETE CASCADE,
    books_read JSONB DEFAULT '{}'::jsonb,
    favorite_topics TEXT[] DEFAULT '{}',
    reading_frequency JSONB DEFAULT '{}'::jsonb,
    last_computed_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- MODERATION TABLES
-- ============================================

-- Reports
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES community_profiles(id) ON DELETE CASCADE,
    target_type report_target_type NOT NULL,
    target_id UUID NOT NULL,
    reason report_reason NOT NULL,
    description TEXT,
    status report_status DEFAULT 'pending',
    ai_flags JSONB,
    assigned_to UUID REFERENCES community_profiles(id) ON DELETE SET NULL,
    resolution TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

-- Mutes
CREATE TABLE mutes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES community_profiles(id) ON DELETE CASCADE,
    muted_id UUID NOT NULL,
    mute_type mute_type NOT NULL,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Moderation Actions
CREATE TABLE moderation_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    moderator_id UUID REFERENCES community_profiles(id) ON DELETE SET NULL,
    target_type report_target_type NOT NULL,
    target_id UUID NOT NULL,
    action moderation_action_type NOT NULL,
    reason TEXT,
    duration_hours INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Keyword Filters
CREATE TABLE keyword_filters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pattern TEXT NOT NULL,
    action filter_action DEFAULT 'flag',
    is_regex BOOLEAN DEFAULT FALSE,
    category filter_category NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Bans
CREATE TABLE user_bans (
    user_id UUID PRIMARY KEY REFERENCES community_profiles(id) ON DELETE CASCADE,
    banned_by UUID REFERENCES community_profiles(id) ON DELETE SET NULL,
    reason TEXT,
    is_permanent BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- VERIFICATION TABLES
-- ============================================

-- Verification Requests
CREATE TABLE verification_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES community_profiles(id) ON DELETE CASCADE,
    type verification_type NOT NULL,
    status verification_status DEFAULT 'pending',
    documents JSONB,
    church_name TEXT,
    church_website TEXT,
    social_links JSONB,
    reviewed_by UUID REFERENCES community_profiles(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    rejection_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- NOTIFICATIONS TABLE
-- ============================================

CREATE TABLE community_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES community_profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT,
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXES
-- ============================================

-- Posts indexes
CREATE INDEX idx_posts_author ON posts(author_id);
CREATE INDEX idx_posts_type ON posts(type);
CREATE INDEX idx_posts_group ON posts(group_id);
CREATE INDEX idx_posts_created ON posts(created_at DESC);
CREATE INDEX idx_posts_visibility ON posts(visibility);
CREATE INDEX idx_posts_verse_ref ON posts USING GIN(verse_ref);
CREATE INDEX idx_posts_tags ON posts USING GIN(tags);

-- Comments indexes
CREATE INDEX idx_comments_post ON comments(post_id);
CREATE INDEX idx_comments_author ON comments(author_id);
CREATE INDEX idx_comments_parent ON comments(parent_comment_id);

-- Reactions indexes
CREATE INDEX idx_reactions_target ON reactions(target_type, target_id);
CREATE INDEX idx_reactions_user ON reactions(user_id);

-- Follows indexes
CREATE INDEX idx_follows_follower ON follows(follower_id);
CREATE INDEX idx_follows_followee ON follows(followee_id);

-- Groups indexes
CREATE INDEX idx_groups_type ON groups(type);
CREATE INDEX idx_groups_privacy ON groups(privacy);

-- Group members indexes
CREATE INDEX idx_group_members_user ON group_members(user_id);
CREATE INDEX idx_group_members_group ON group_members(group_id);

-- Messages indexes
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_created ON messages(created_at DESC);

-- Live rooms indexes
CREATE INDEX idx_live_rooms_status ON live_rooms(status);
CREATE INDEX idx_live_rooms_host ON live_rooms(host_id);
CREATE INDEX idx_live_rooms_scheduled ON live_rooms(scheduled_at);

-- Prayer indexes
CREATE INDEX idx_prayer_requests_category ON prayer_requests(category);
CREATE INDEX idx_prayer_requests_answered ON prayer_requests(is_answered);
CREATE INDEX idx_prayer_circle_user ON prayer_circle_members(user_id);

-- Verse index
CREATE INDEX idx_verse_index_book ON verse_index(book, chapter);
CREATE INDEX idx_verse_index_activity ON verse_index(last_activity_at DESC);

-- Trending cache
CREATE INDEX idx_trending_type ON trending_cache(type);
CREATE INDEX idx_trending_score ON trending_cache(score DESC);

-- Reports indexes
CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_target ON reports(target_type, target_id);

-- Notifications indexes
CREATE INDEX idx_notifications_user ON community_notifications(user_id);
CREATE INDEX idx_notifications_read ON community_notifications(is_read);
CREATE INDEX idx_notifications_created ON community_notifications(created_at DESC);

-- Location indexes for nearby feature
CREATE INDEX idx_profiles_location_lat ON community_profiles(location_lat);
CREATE INDEX idx_profiles_location_lng ON community_profiles(location_lng);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE community_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE live_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE prayer_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE prayer_circle_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE prayer_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE mutes ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_notifications ENABLE ROW LEVEL SECURITY;

-- Helper function to check group membership (bypasses RLS to avoid infinite recursion)
CREATE OR REPLACE FUNCTION is_group_member(p_group_id UUID, p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM group_members 
        WHERE group_id = p_group_id AND user_id = p_user_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- RLS Policies

-- Profiles: Anyone can read public profiles, users can update their own
CREATE POLICY "Public profiles are viewable by everyone" ON community_profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON community_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON community_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Posts: Visible based on visibility level
CREATE POLICY "Public posts are viewable by everyone" ON posts
    FOR SELECT USING (
        visibility = 'public' 
        OR author_id = auth.uid()
        OR (visibility = 'followers' AND EXISTS (
            SELECT 1 FROM follows WHERE follower_id = auth.uid() AND followee_id = posts.author_id AND state = 'active'
        ))
        OR (visibility = 'group' AND is_group_member(posts.group_id, auth.uid()))
    );

CREATE POLICY "Users can create posts" ON posts
    FOR INSERT WITH CHECK (auth.uid() = author_id OR is_anonymous = true);

CREATE POLICY "Users can update own posts" ON posts
    FOR UPDATE USING (auth.uid() = author_id);

CREATE POLICY "Users can delete own posts" ON posts
    FOR DELETE USING (auth.uid() = author_id);

-- Comments: Viewable if post is viewable
CREATE POLICY "Comments viewable if post is viewable" ON comments
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM posts WHERE posts.id = comments.post_id)
    );

CREATE POLICY "Users can create comments" ON comments
    FOR INSERT WITH CHECK (auth.uid() = author_id OR is_anonymous = true);

CREATE POLICY "Users can update own comments" ON comments
    FOR UPDATE USING (auth.uid() = author_id);

-- Reactions: Users can manage their own
CREATE POLICY "Reactions viewable by everyone" ON reactions
    FOR SELECT USING (true);

CREATE POLICY "Users can create reactions" ON reactions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own reactions" ON reactions
    FOR DELETE USING (auth.uid() = user_id);

-- Follows: Users can manage their own follows
CREATE POLICY "Follows viewable by everyone" ON follows
    FOR SELECT USING (true);

CREATE POLICY "Users can create follows" ON follows
    FOR INSERT WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can delete own follows" ON follows
    FOR DELETE USING (auth.uid() = follower_id);

-- Blocks: Users can manage their own blocks
CREATE POLICY "Users can view own blocks" ON blocks
    FOR SELECT USING (auth.uid() = blocker_id);

CREATE POLICY "Users can create blocks" ON blocks
    FOR INSERT WITH CHECK (auth.uid() = blocker_id);

CREATE POLICY "Users can delete own blocks" ON blocks
    FOR DELETE USING (auth.uid() = blocker_id);

-- Groups: Public groups viewable by everyone, private groups by members only
CREATE POLICY "Public groups viewable by everyone" ON groups
    FOR SELECT USING (
        privacy = 'public' 
        OR is_group_member(groups.id, auth.uid())
    );

CREATE POLICY "Users can create groups" ON groups
    FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Group Members: Simple policy using helper function to avoid infinite recursion
CREATE POLICY "Group members viewable" ON group_members
    FOR SELECT USING (
        -- User can always see their own memberships
        user_id = auth.uid()
        -- Or if the group is public, anyone can see members
        OR EXISTS (SELECT 1 FROM groups WHERE groups.id = group_members.group_id AND groups.privacy = 'public')
        -- Or user is a member of this group (uses SECURITY DEFINER function)
        OR is_group_member(group_id, auth.uid())
    );

-- Messages: Only participants can view
CREATE POLICY "Messages viewable by participants" ON messages
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM conversations WHERE conversations.id = messages.conversation_id AND auth.uid() = ANY(conversations.participant_ids))
    );

CREATE POLICY "Users can send messages" ON messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Notifications: Users can only see their own
CREATE POLICY "Users can view own notifications" ON community_notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications" ON community_notifications
    FOR UPDATE USING (auth.uid() = user_id);

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Function to update engagement counts
CREATE OR REPLACE FUNCTION update_post_engagement()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE posts 
        SET engagement = jsonb_set(
            engagement, 
            ARRAY[NEW.reaction_type::text], 
            to_jsonb(COALESCE((engagement->>NEW.reaction_type::text)::int, 0) + 1)
        )
        WHERE id = NEW.target_id AND NEW.target_type = 'post';
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts 
        SET engagement = jsonb_set(
            engagement, 
            ARRAY[OLD.reaction_type::text], 
            to_jsonb(GREATEST(COALESCE((engagement->>OLD.reaction_type::text)::int, 0) - 1, 0))
        )
        WHERE id = OLD.target_id AND OLD.target_type = 'post';
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_post_engagement
AFTER INSERT OR DELETE ON reactions
FOR EACH ROW EXECUTE FUNCTION update_post_engagement();

-- Function to update follower counts
CREATE OR REPLACE FUNCTION update_follow_counts()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.state = 'active' THEN
        UPDATE community_profiles SET following_count = following_count + 1 WHERE id = NEW.follower_id;
        UPDATE community_profiles SET follower_count = follower_count + 1 WHERE id = NEW.followee_id;
    ELSIF TG_OP = 'DELETE' AND OLD.state = 'active' THEN
        UPDATE community_profiles SET following_count = GREATEST(following_count - 1, 0) WHERE id = OLD.follower_id;
        UPDATE community_profiles SET follower_count = GREATEST(follower_count - 1, 0) WHERE id = OLD.followee_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_follow_counts
AFTER INSERT OR DELETE ON follows
FOR EACH ROW EXECUTE FUNCTION update_follow_counts();

-- Function to update post counts
CREATE OR REPLACE FUNCTION update_post_counts()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE community_profiles SET post_count = post_count + 1 WHERE id = NEW.author_id;
        IF NEW.group_id IS NOT NULL THEN
            UPDATE groups SET post_count = post_count + 1 WHERE id = NEW.group_id;
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE community_profiles SET post_count = GREATEST(post_count - 1, 0) WHERE id = OLD.author_id;
        IF OLD.group_id IS NOT NULL THEN
            UPDATE groups SET post_count = GREATEST(post_count - 1, 0) WHERE id = OLD.group_id;
        END IF;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_post_counts
AFTER INSERT OR DELETE ON posts
FOR EACH ROW EXECUTE FUNCTION update_post_counts();

-- Function to update group member counts
CREATE OR REPLACE FUNCTION update_group_member_counts()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE groups SET member_count = member_count + 1 WHERE id = NEW.group_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE groups SET member_count = GREATEST(member_count - 1, 0) WHERE id = OLD.group_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_group_member_counts
AFTER INSERT OR DELETE ON group_members
FOR EACH ROW EXECUTE FUNCTION update_group_member_counts();

-- Function to update verse index
CREATE OR REPLACE FUNCTION update_verse_index()
RETURNS TRIGGER AS $$
DECLARE
    v_book TEXT;
    v_chapter INT;
    v_verse INT;
    v_translation TEXT;
BEGIN
    IF NEW.verse_ref IS NOT NULL THEN
        v_book := NEW.verse_ref->>'book';
        v_chapter := (NEW.verse_ref->>'chapter')::INT;
        v_verse := (NEW.verse_ref->>'start_verse')::INT;
        v_translation := COALESCE(NEW.verse_ref->>'translation_id', 'KJV');
        
        INSERT INTO verse_index (book, chapter, verse, translation_id, post_ids, post_count, last_activity_at)
        VALUES (v_book, v_chapter, v_verse, v_translation, ARRAY[NEW.id], 1, NOW())
        ON CONFLICT (book, chapter, verse, translation_id)
        DO UPDATE SET 
            post_ids = array_append(verse_index.post_ids, NEW.id),
            post_count = verse_index.post_count + 1,
            last_activity_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_verse_index
AFTER INSERT ON posts
FOR EACH ROW EXECUTE FUNCTION update_verse_index();

-- Function to update prayer count in profiles
CREATE OR REPLACE FUNCTION update_prayer_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE community_profiles SET prayer_count = prayer_count + 1 WHERE id = NEW.user_id;
        UPDATE prayer_requests SET prayer_count = prayer_count + 1 WHERE post_id = NEW.prayer_post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE community_profiles SET prayer_count = GREATEST(prayer_count - 1, 0) WHERE id = OLD.user_id;
        UPDATE prayer_requests SET prayer_count = GREATEST(prayer_count - 1, 0) WHERE post_id = OLD.prayer_post_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_prayer_count
AFTER INSERT OR DELETE ON prayer_circle_members
FOR EACH ROW EXECUTE FUNCTION update_prayer_count();

-- Function to update comment counts
CREATE OR REPLACE FUNCTION update_comment_counts()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE posts 
        SET engagement = jsonb_set(engagement, '{comments}', to_jsonb(COALESCE((engagement->>'comments')::int, 0) + 1))
        WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts 
        SET engagement = jsonb_set(engagement, '{comments}', to_jsonb(GREATEST(COALESCE((engagement->>'comments')::int, 0) - 1, 0)))
        WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_comment_counts
AFTER INSERT OR DELETE ON comments
FOR EACH ROW EXECUTE FUNCTION update_comment_counts();

-- Function to auto-set updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_profiles_updated_at
BEFORE UPDATE ON community_profiles
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trigger_posts_updated_at
BEFORE UPDATE ON posts
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trigger_comments_updated_at
BEFORE UPDATE ON comments
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trigger_groups_updated_at
BEFORE UPDATE ON groups
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

