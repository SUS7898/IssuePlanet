package com.care.boot.board;

import java.util.List;
import java.util.Map;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface BoardMapper {
    // 게시판 서비스 인터페이스
    List<BoardDTO> boardForm(Map<String, Object> map);
    int boardCount(String category);
    void boardWriteProc(BoardDTO board);
    BoardDTO boardContent(int no);
    void incHit(int no);
    
    // 댓글 관련 데이터 조작 매핑
    void insertReply(ReplyDTO reply);
    List<ReplyDTO> getReplies(int boardNo);
    
    // 좋아요 관련 데이터 조작 매핑
    int checkLike(Map<String, Object> map);
    void insertLike(Map<String, Object> map);
    void deleteLike(Map<String, Object> map);
    void updateBoardLike(int no);
}