package com.care.boot.board;

import java.io.File;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.ui.Model;
import org.springframework.web.multipart.MultipartFile;

@Service
public class BoardService {

    @Autowired private BoardMapper mapper;

    // 카테고리별 페이징 처리 리스트
    public void boardForm(String cp, String category, Model model) {
        int currentPage = 1;
        try { currentPage = Integer.parseInt(cp); } catch(Exception e) {}
        
        int pageBlock = 10;
        int end = currentPage * pageBlock;
        int begin = end + 1 - pageBlock;
        
        Map<String, Object> map = new HashMap<>();
        map.put("category", category);
        map.put("begin", begin - 1); // MariaDB LIMIT 오프셋 보정
        map.put("end", pageBlock);
        
        List<BoardDTO> list = mapper.boardForm(map);
        int totalCount = mapper.boardCount(category);
        
        model.addAttribute("boardList", list);
        model.addAttribute("totalCount", totalCount);
    }

    // 게시글 저장
    public void boardWriteProc(BoardDTO board, MultipartFile file) {
        if(!file.isEmpty()) {
            String fileName = file.getOriginalFilename();
            String path = "D:/issueplanet/uploads/" + fileName;
            try {
                file.transferTo(new File(path));
                board.setFileName(fileName); // 파일명을 DB에 저장할 DTO에 세팅
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        board.setWriteDate(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));
        mapper.boardWriteProc(board);
    }

    // 상세 내용 및 댓글 로드
    public void boardContent(int no, Model model) {
        mapper.incHit(no);
        model.addAttribute("board", mapper.boardContent(no));
        model.addAttribute("replies", mapper.getReplies(no));
    }

    // 댓글 등록
    public void insertReply(ReplyDTO reply) {
        reply.setWriteDate(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()));
        mapper.insertReply(reply);
    }

    // 좋아요 이력 체크
    public boolean checkLike(int boardNo, String id) {
        Map<String, Object> map = new HashMap<>();
        map.put("boardNo", boardNo);
        map.put("id", id);
        return mapper.checkLike(map) > 0;
    }

    // 좋아요 On/Off 토글 비즈니스 로직
    public int toggleLike(int boardNo, String id) {
        Map<String, Object> map = new HashMap<>();
        map.put("boardNo", boardNo);
        map.put("id", id);
        
        if (mapper.checkLike(map) > 0) {
            mapper.deleteLike(map); // 기등록 시 취소
        } else {
            mapper.insertLike(map); // 미등록 시 추가
        }
        mapper.updateBoardLike(boardNo); // board 테이블 누적 카운트 갱신
        return mapper.boardContent(boardNo).getLikes();
    }
}