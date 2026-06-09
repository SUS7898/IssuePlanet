package com.care.boot.board;

import java.util.HashMap;
import java.util.Map;
import java.io.File;
import java.nio.file.Files;

import jakarta.servlet.ServletContext;
import jakarta.servlet.http.HttpSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;

@Controller
@RequestMapping("/board")
public class BoardController {

    @Autowired private BoardService service;
    @Autowired private HttpSession session;
    @Autowired private ServletContext servletContext;

    // 게시판 메인 리스트로 이동
    @GetMapping("/boardForm")
    public String boardForm(@RequestParam(value="category", defaultValue="news") String category,
                            @RequestParam(value="currentPage", defaultValue="1") String currentPage,
                            Model model) {
        service.boardForm(currentPage, category, model);
        model.addAttribute("category", category);
        return "board/boardForm";
    }

    // 글쓰기 폼 이동
    @GetMapping("/boardWrite")
    public String boardWrite() {
        return "board/boardWrite";
    }

    // 글 등록 처리
    @PostMapping("/boardWriteProc")
    public String boardWriteProc(BoardDTO board, @RequestParam("file") MultipartFile file) {
        String id = (String) session.getAttribute("id");
        if(id == null) return "redirect:/member/login";
        board.setId(id);
        service.boardWriteProc(board, file);
        return "redirect:/board/boardForm?category=" + board.getCategory();
    }

    // 본문 상세보기 (좋아요 유무 체크 바인딩)
    @GetMapping("/boardContent")
    public String boardContent(@RequestParam("no") int no, Model model, HttpSession session) {
        service.boardContent(no, model);
        
        String id = (String) session.getAttribute("id");
        if(id != null) {
            boolean isLiked = service.checkLike(no, id);
            model.addAttribute("isLiked", isLiked);
        }
        return "board/boardContent";
    }

    // 댓글 저장 라우터
    @PostMapping("/replyWrite")
    public String replyWrite(ReplyDTO reply, HttpSession session) {
        String id = (String) session.getAttribute("id");
        if(id != null) {
            reply.setId(id);
            service.insertReply(reply);
        }
        return "redirect:/board/boardContent?no=" + reply.getBoardNo();
    }

    // 좋아요 비동기 요청 API 토글
    @ResponseBody
    @PostMapping("/toggleLike")
    public Map<String, Object> toggleLike(@RequestParam("no") int no, HttpSession session) {
        Map<String, Object> response = new HashMap<>();
        String id = (String) session.getAttribute("id");
        
        if(id == null) {
            response.put("status", "login_required");
            return response;
        }
        
        int currentLikes = service.toggleLike(no, id);
        response.put("status", "success");
        response.put("likes", currentLikes);
        return response;
    }
    
    // [★ 핵심 수정] display 메서드의 경로를 실제 파일이 저장된 리눅스 톰캣 절대 경로로 완벽하게 일치시킵니다.
    @GetMapping("/display")
    public ResponseEntity<Resource> display(@RequestParam("fileName") String fileName) {
        
        // 업로드 시 지정했던 경로와 정확히 일치하는 리눅스 절대 경로
        String uploadPath = "/opt/tomcat/tomcat-10/webapps/uploads/";
        File file = new File(uploadPath, fileName);
        
        if (!file.exists()) {
            return ResponseEntity.notFound().build();
        }
        
        Resource resource = new FileSystemResource(file);
        HttpHeaders headers = new HttpHeaders();
        
        try {
            // 브라우저가 png, jpg 등 파일의 포맷을 정확히 인식하여 렌더링하도록 Content-Type 동적 할당
            String mimeType = Files.probeContentType(file.toPath());
            headers.add(HttpHeaders.CONTENT_TYPE, mimeType != null ? mimeType : "image/png");
        } catch (Exception e) {
            headers.add(HttpHeaders.CONTENT_TYPE, "image/png");
        }
        
        return ResponseEntity.ok()
                .headers(headers)
                .body(resource);
    }
}