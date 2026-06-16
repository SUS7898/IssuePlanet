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
import jakarta.servlet.ServletContext;

import org.springframework.web.util.HtmlUtils;

@Service
public class BoardService {

    @Autowired private BoardMapper mapper;
    @Autowired private ServletContext servletContext;

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

    // 게시글 저장 및 파일 업로드 (리눅스 경로로 수정)
 // 게시글 저장 및 파일 업로드 (리눅스 절대 경로 + 한글/공백 파일명 에러 방지)
    public void boardWriteProc(BoardDTO board, MultipartFile file) {
    	// =======================================================
        // [보안 조치] Spring 내장 유틸을 이용한 XSS 필터링 처리 (버전 충돌 없음)
        // =======================================================
        if (board.getContent() != null) {
            // <script>alert(1);</script> 단어를 &lt;script&gt; 형태로 안전하게 이스케이프 변환합니다.
            String cleanContent = HtmlUtils.htmlEscape(board.getContent());
            board.setContent(cleanContent);
        }
        // =======================================================
    	
    	if(file != null && !file.isEmpty()) {
            
            String uploadPath = "/opt/tomcat/tomcat-10/webapps/uploads/";
            File uploadDir = new File(uploadPath);
            
            // 폴더가 존재하지 않으면 자동으로 생성합니다.
            if(!uploadDir.exists()) {
                uploadDir.mkdirs();
            }
            
            String originalName = file.getOriginalFilename();
            String extension = "";
            
            // 파일의 확장자(.png, .jpg 등)만 추출
            if(originalName.contains(".")) {
                extension = originalName.substring(originalName.lastIndexOf("."));
            }
            
            // [★ 핵심] 리눅스 404 에러와 덮어쓰기 방지를 위해 파일명을 고유한 숫자(밀리초)로 변환
            // 예: "프로젝트 테스트3.png" -> "1717891234567.png"
            String savedFileName = System.currentTimeMillis() + extension;
            
            File saveFile = new File(uploadDir, savedFileName);
            
            try {
                file.transferTo(saveFile);
                // DB에도 변환된 안전한 파일명으로 저장
                board.setFileName(savedFileName); 
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