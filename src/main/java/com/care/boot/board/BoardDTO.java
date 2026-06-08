package com.care.boot.board;
public class BoardDTO {
    private int no;
    private String category;
    private String title;
    private String content;
    private String id;
    private String writeDate;
    private int hit;
    private String fileName;
    private int likes;

    public int getNo() { return no; }
    public void setNo(int no) { this.no = no; }
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getWriteDate() { return writeDate; }
    public void setWriteDate(String writeDate) { this.writeDate = writeDate; }
    public int getHit() { return hit; }
    public void setHit(int hit) { this.hit = hit; }
    public String getFileName() { return fileName; }
    public void setFileName(String fileName) { this.fileName = fileName; }
    public int getLikes() { return likes; }
    public void setLikes(int likes) { this.likes = likes; }
}