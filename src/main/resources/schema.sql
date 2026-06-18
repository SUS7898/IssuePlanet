-- 1. 회원 테이블
CREATE TABLE IF NOT EXISTS member (
    id            VARCHAR(20),
    pw            VARCHAR(200),
    username      VARCHAR(99),
    postcode      VARCHAR(20),
    address       VARCHAR(1000),
    detailaddress VARCHAR(100),
    mobile        VARCHAR(15),
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. 게시판 테이블
CREATE TABLE IF NOT EXISTS board (
    no        INT AUTO_INCREMENT,
    category  VARCHAR(50) NOT NULL,
    title     VARCHAR(200),
    content   TEXT,
    id        VARCHAR(20),
    writedate VARCHAR(100),
    hit       INT DEFAULT 0,
    filename  VARCHAR(1000),
    likes     INT DEFAULT 0,
    PRIMARY KEY (no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. 댓글 테이블
CREATE TABLE IF NOT EXISTS reply (
    reply_no  INT AUTO_INCREMENT,
    board_no  INT,
    id        VARCHAR(20),
    content   VARCHAR(1000),
    writedate VARCHAR(100),
    PRIMARY KEY (reply_no),
    FOREIGN KEY (board_no) REFERENCES board(no) ON DELETE CASCADE,
    FOREIGN KEY (id)       REFERENCES member(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. 좋아요 테이블
CREATE TABLE IF NOT EXISTS board_like (
    like_no  INT AUTO_INCREMENT,
    board_no INT,
    id       VARCHAR(20),
    PRIMARY KEY (like_no),
    FOREIGN KEY (board_no) REFERENCES board(no) ON DELETE CASCADE,
    FOREIGN KEY (id)       REFERENCES member(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
