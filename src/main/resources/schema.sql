-- 1. 회원 테이블
CREATE TABLE IF NOT EXISTS member (
    id varchar(20),
    pw varchar(200),
    username varchar(99),
    postcode varchar(20),
    address varchar(1000),
    detailaddress varchar(100),
    mobile varchar(15),
    PRIMARY KEY(id)
) DEFAULT CHARSET=UTF8;

-- 2. 게시판 테이블
CREATE TABLE IF NOT EXISTS board (
    no int AUTO_INCREMENT,
    category varchar(50) NOT NULL,
    title varchar(200),
    content varchar(9999),
    id varchar(20),
    writedate varchar(100),
    hit int DEFAULT 0,
    filename varchar(1000),
    likes int DEFAULT 0,
    PRIMARY KEY(no)
) DEFAULT CHARSET=UTF8;

-- 3. 댓글 테이블
CREATE TABLE IF NOT EXISTS reply (
    reply_no int AUTO_INCREMENT,
    board_no int,
    id varchar(20),
    content varchar(1000),
    writedate varchar(100),
    PRIMARY KEY(reply_no),
    FOREIGN KEY (board_no) REFERENCES board(no) ON DELETE CASCADE,
    FOREIGN KEY (id) REFERENCES member(id) ON DELETE CASCADE
) DEFAULT CHARSET=UTF8;

-- 4. 좋아요 테이블
CREATE TABLE IF NOT EXISTS board_like (
    like_no int AUTO_INCREMENT,
    board_no int,
    id varchar(20),
    PRIMARY KEY(like_no),
    FOREIGN KEY (board_no) REFERENCES board(no) ON DELETE CASCADE,
    FOREIGN KEY (id) REFERENCES member(id) ON DELETE CASCADE
) DEFAULT CHARSET=UTF8;
