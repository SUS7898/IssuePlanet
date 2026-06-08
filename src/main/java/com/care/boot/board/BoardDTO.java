package com.care.boot.board;
/*
CREATE TABLE board(
no INT,
title VARCHAR(100),
content VARCHAR(200),
id VARCHAR(20),
writedate VARCHAR(15),
hits INT,
filename VARCHAR(255),
PRIMARY KEY(no)
)DEFAULT CHARSET=UTF8;

 */
public class BoardDTO {
	private int no;
	private String title;
	private String content;
	private String id;
	private String writeDate; // 2023-09-22
	private int hits;
	private String fileName;
	
	public int getNo() {
		return no;
	}
	public void setNo(int no) {
		this.no = no;
	}
	public String getTitle() {
		return title;
	}
	public void setTitle(String title) {
		this.title = title;
	}
	public String getContent() {
		return content;
	}
	public void setContent(String content) {
		this.content = content;
	}
	public String getId() {
		return id;
	}
	public void setId(String id) {
		this.id = id;
	}
	public String getWriteDate() {
		return writeDate;
	}
	public void setWriteDate(String writeDate) {
		this.writeDate = writeDate;
	}
	public int getHits() {
		return hits;
	}
	public void setHits(int hits) {
		this.hits = hits;
	}
	public String getFileName() {
		return fileName;
	}
	public void setFileName(String fileName) {
		this.fileName = fileName;
	}
	
}


/*
INSERT INTO board_quiz 
VALUES(1, 'admin 게시글 제목', 'admin 게시글 내용', 'admin', '2023-09-22', 0, '');
INSERT INTO board_quiz 
VALUES(2, 'user1 게시글 제목', 'user1 게시글 내용', 'user1', '2023-09-22', 0, '');
INSERT INTO board_quiz 
VALUES(3, 'user2 게시글 제목', 'user2 게시글 내용', 'user2', '2023-09-23', 0, '');
INSERT INTO board_quiz 
VALUES(4, 'test1 게시글 제목', 'test1 게시글 내용', 'test1', '2023-09-23', 0, '');
INSERT INTO board_quiz 
VALUES(5, 'test2 게시글 제목', 'test2 게시글 내용', 'test2', '2023-09-24', 0, '');
COMMIT;
*/
