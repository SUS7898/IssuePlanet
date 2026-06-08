package com.care.boot.board;

public class ReplyDTO {
    private int replyNo;
    private int boardNo;
    private String id;
    private String content;
    private String writeDate;

    // Getter & Setter
    public int getReplyNo() { return replyNo; }
    public void setReplyNo(int replyNo) { this.replyNo = replyNo; }
    public int getBoardNo() { return boardNo; }
    public void setBoardNo(int boardNo) { this.boardNo = boardNo; }
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    public String getWriteDate() { return writeDate; }
    public void setWriteDate(String writeDate) { this.writeDate = writeDate; }
}